//
//  AppState.swift
//  BanBan
//
//  全局应用状态：阶段流转（引导 → 注册 → 主流程）、资料草稿、推荐卡片、会话与筛选
//

import SwiftUI

enum AppPhase: Equatable {
    case onboarding
    case registration
    case main
}

/// 深浅色偏好：规格为 Toggle 双态（仅 light/dark），跟随系统暂不支持
enum PreferredScheme: String {
    case light
    case dark

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var phase: AppPhase = .onboarding
    @Published var preferredColorScheme: PreferredScheme = .dark
    @Published var myProfile = MyProfile()
    @Published var draft = ProfileDraft()
    @Published var recommendations: [UserProfile] = []
    @Published var cardIndex = 0
    /// 推荐列表拉取中（空态区分「加载中」与「真的没有更多」）
    @Published var isLoadingRecommendations = false
    @Published var likedUserIDs: Set<String> = []
    @Published var skippedUserIDs: Set<String> = []
    @Published var matchUser: UserProfile?
    @Published var pendingChatUserID: String?
    @Published var conversations: [Conversation] = []
    @Published var filter = FilterState()
    /// 推荐拉取 / like / skip 失败的提示文案（视图层展示后置 nil 复位）
    @Published var homeError: String?

    // MARK: 聊天（P9 接后端 + WebSocket）

    /// WebSocket 连接状态（MessagesView 顶栏可展示断线提示）
    @Published private(set) var chatConnection: WebSocketClient.ConnectionState = .idle
    /// 当前在线的匹配对象（ChatView 头部绿点）
    @Published private(set) var onlineUserIDs: Set<String> = []
    /// 对方正在输入的会话（ChatView 底部提示，几秒后自动消失）
    @Published private(set) var typingConversationIDs: Set<String> = []
    /// 我自己的 user id（isMe 映射 / 参与方判定，登录后从 access token 解出）
    @Published private(set) var myUserID: String?

    // MARK: 认证态（P2 接后端登录）

    /// 认证栈导航路径（OnboardingFlowView 的 NavigationStack 绑定此数组）
    @Published var authPath: [AuthRoute] = []
    @Published var isSendingCode = false
    @Published var isVerifying = false
    /// 登录/发送验证码失败的提示文案（视图层展示后置 nil 复位）
    @Published var authError: String?
    /// 开发环境验证码回显（后端 APP_DEBUG=true 才下发，生产恒为 nil）
    @Published private(set) var debugCode: String?
    /// 最近一次发送验证码的手机号（验证码页脱敏展示）
    @Published private(set) var lastSentPhone: String?
    /// 登录结果：true = 新注册（引导进注册流）
    @Published private(set) var isNewUser = false

    private let authRepository: AuthRepository
    /// 与 authRepository 共享同一 APIClient（共享 Keychain 令牌与 401 刷新链路）
    private let userRepository: UserRepository
    /// 推荐与匹配仓库（同一 APIClient）
    private let matchRepository: MatchRepository
    /// 会话与消息仓库（同一 APIClient）
    private let chatRepository: ChatRepository
    /// 筛选条件仓库（同一 APIClient）
    private let filterRepository: FilterRepository
    /// WebSocket 客户端（聊天实时通道）
    private let socket = WebSocketClient()
    /// 共享 API 客户端（WS URL 派生自 serverRootURL）
    private let client: APIClient
    /// 历史分页游标：conversationID → 下一页（更早）cursor
    private var historyCursors: [String: String] = [:]

    /// 资料 bootstrap / 保存失败的提示文案（视图层展示后置 nil 复位）
    @Published var profileError: String?
    /// 本机 APNs device token hex（登出时凭此注销服务端绑定）
    private var deviceToken: String?

    init(client: APIClient = APIClient()) {
        self.client = client
        self.authRepository = AuthRepository(client: client)
        self.userRepository = UserRepository(client: client)
        self.matchRepository = MatchRepository(client: client)
        self.chatRepository = ChatRepository(client: client)
        self.filterRepository = FilterRepository(client: client)
        // 启动恢复：Keychain 有令牌直接进主流程，并异步拉取服务端资料
        if authRepository.tokens.hasTokens {
            phase = .main
            Task { await bootstrapProfile() }
        }
        socket.onEvent = { [weak self] event in
            self?.handleSocketEvent(event)
        }
        socket.onStateChange = { [weak self] state in
            self?.chatConnection = state
        }
    }

    var currentCard: UserProfile? {
        guard recommendations.indices.contains(cardIndex) else { return nil }
        return recommendations[cardIndex]
    }

    /// 未读总数：各会话未读求和
    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    /// 会话按最近消息时间倒序（nil 沉底；ForEach 用 id 保持行稳定）
    var sortedConversations: [Conversation] {
        conversations.sorted {
            ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
        }
    }

    func completeOnboarding() {
        draft = ProfileDraft()
        phase = .registration
    }

    /// 进入编辑模式：以当前资料全量回填 draft（唯一映射见 ProfileDraft.init(from:)）
    func startEditProfile() {
        draft = ProfileDraft(from: myProfile)
    }

    // MARK: 资料同步（P4 接后端 /me/profile）

    /// 老用户登录进主流程：切相位 + 拉取服务端资料
    func enterMainAfterLogin() {
        phase = .main
        Task { await bootstrapProfile() }
    }

    /// 拉取服务端资料并全量覆盖本地（启动恢复与登录后共用），随后拉取筛选、推荐与会话、连 WS
    func bootstrapProfile() async {
        do {
            myProfile = MyProfile(response: try await userRepository.getProfile())
        } catch {
            profileError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        // 静默恢复服务端筛选（首次使用时后端惰性建行返回默认值；失败不阻塞主流程）
        if let restored = try? await filterRepository.fetchFilter() {
            filter = restored
        }
        await loadRecommendations()
        await loadConversations()
        connectChat()
        registerPushNotifications()
    }

    /// 注册 APNs 推送：授权请求 → 系统回调回传 token → 上报服务端（失败静默，不阻塞主流程）
    private func registerPushNotifications() {
        NotificationManager.shared.onToken = { [weak self] hex in
            guard let self else { return }
            deviceToken = hex
            Task { try? await self.userRepository.registerDeviceToken(token: hex) }
        }
        NotificationManager.shared.register()
    }

    /// 拉取后端推荐列表并重置卡片游标（耗尽后可再次调用刷新）
    func loadRecommendations() async {
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }
        do {
            recommendations = try await matchRepository.fetchRecommendations()
            cardIndex = 0
        } catch {
            homeError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// 应用筛选：先 PUT 服务端（全量覆盖），成功后更新本地并以新筛选重新拉推荐
    /// 返回 false 时错误已写入 homeError，调用方留在筛选页展示
    func applyFilter(_ newFilter: FilterState) async -> Bool {
        do {
            try await filterRepository.saveFilter(newFilter)
            filter = newFilter
            await loadRecommendations()
            return true
        } catch {
            homeError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 注册向导提交：增量合并 → 提交完成 → 以服务端合并结果覆盖本地 → 进主流程
    /// 返回 false 时错误已写入 profileError，调用方留在向导展示
    func submitRegistration() async -> Bool {
        do {
            let merged = try await userRepository.updateProfile(ProfileUpdateRequest(from: draft))
            _ = try await userRepository.submitProfile()
            // PUT 响应即合并后完整资料（completion 公式不含 profile_submitted，无需再回读）
            myProfile = MyProfile(response: merged)
            draft = ProfileDraft()
            phase = .main
            return true
        } catch {
            profileError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 编辑资料保存：增量合并 → 以服务端合并结果覆盖本地
    func saveProfileEdits() async -> Bool {
        do {
            let merged = try await userRepository.updateProfile(ProfileUpdateRequest(from: draft))
            myProfile = MyProfile(response: merged)
            return true
        } catch {
            profileError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 推进卡片：cardIndex 允许等于 count（哨兵位，表示卡片已耗尽），故用 min 兜底
    func advanceCard() {
        cardIndex = min(cardIndex + 1, recommendations.count)
    }

    /// 喜欢：后端登记成功才推进卡片；双向命中时弹匹配成功（对方即当前卡片，无需回查）
    func likeCurrent() async {
        guard let user = currentCard else { return }
        do {
            let result = try await matchRepository.like(userID: user.id)
            likedUserIDs.insert(user.id)
            advanceCard()
            if result.matched { matchUser = user }
        } catch {
            homeError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// 跳过：后端登记成功才推进卡片（失败可原地重试）
    func skipCurrent() async {
        guard let user = currentCard else { return }
        do {
            try await matchRepository.skip(userID: user.id)
            skippedUserIDs.insert(user.id)
            advanceCard()
        } catch {
            homeError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func startChatAfterMatch() {
        pendingChatUserID = matchUser?.id
        matchUser = nil
    }

    func dismissMatch() {
        matchUser = nil
    }

    // MARK: 会话 / 消息（P9 接后端）

    /// 拉取会话列表（合并保留既有历史消息：列表接口不带消息体）
    func loadConversations() async {
        do {
            let items = try await chatRepository.fetchConversations()
            let serverRoot = client.serverRootURL
            conversations = items.map { response in
                let user = response.user.userProfile(serverRoot: serverRoot)
                let existing = conversations.first { $0.id == response.id }
                return Conversation(
                    id: response.id,
                    user: user,
                    lastMessage: response.lastMessageText ?? "",
                    lastMessageAt: response.lastMessageAt,
                    unreadCount: response.unreadCount,
                    messages: existing?.messages ?? [],
                    hasMoreHistory: existing?.hasMoreHistory ?? false
                )
            }
        } catch {
            // 会话列表拉取失败静默：下次进入消息页 / 收到 WS 事件时重试
        }
    }

    /// 拉取某会话的消息历史（首次进入拉最新一页，之后按游标加载更早）
    func loadMessages(conversationID: String, loadOlder: Bool = false) async {
        guard conversations.contains(where: { $0.id == conversationID }) else { return }
        // 首次进入或加载更早：有游标且已无更多则跳过
        let cursor = loadOlder ? historyCursors[conversationID] : nil
        if loadOlder && cursor == nil { return }
        do {
            let page = try await chatRepository.fetchMessages(
                conversationID: conversationID, cursor: cursor
            )
            guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
            let mapped = page.items.map { message in
                message.chatMessage(myUserID: myUserID)
            }
            conversations[index].messages = mapped + conversations[index].messages
            conversations[index].hasMoreHistory = page.nextCursor != nil
            historyCursors[conversationID] = page.nextCursor
        } catch {
            // 历史拉取失败静默：可再次点击「加载更早消息」重试
        }
    }

    /// 发送消息：乐观插入 pending 气泡 → WS 主通道；未连接时 HTTP 兜底
    func send(to conversationID: String, text: String) async {
        guard conversations.contains(where: { $0.id == conversationID }) else { return }
        let clientMsgID = UUID().uuidString
        // 乐观插入：ack 到达后按 client_msg_id 替换为服务端 id
        appendMessage(
            to: conversationID,
            ChatMessage(id: clientMsgID, isMe: true, text: text, timestamp: Date(), isPending: true)
        )
        let delivered = socket.send([
            "type": "message",
            "conversation_id": conversationID,
            "content": text,
            "client_msg_id": clientMsgID,
        ])
        guard !delivered else { return }
        // WS 未连接：HTTP 兜底发送
        do {
            let message = try await chatRepository.sendMessage(
                conversationID: conversationID, content: text, clientMsgID: clientMsgID
            )
            applyAck(conversationID: conversationID, clientMsgID: clientMsgID, message: message)
        } catch {
            // 发送失败：pending 气泡保留（用户可重发），错误由下次操作时呈现
        }
    }

    /// 进入会话：本地未读清零 + 通知服务端已读
    func markConversationRead(_ conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
        Task { try? await chatRepository.markRead(conversationID: conversationID) }
    }

    /// 匹配成功后进入聊天：刷新会话列表后返回对应会话 id
    /// （后端双向 like 时已同步建会话，无需本地伪造）
    func ensureConversation(for userID: String) async -> String? {
        await loadConversations()
        return conversations.first { $0.user.id == userID }?.id
    }

    // MARK: WebSocket 事件处理

    private func connectChat() {
        guard let token = authRepository.tokens.readAccess() else { return }
        myUserID = JWT.sub(token)
        var components = URLComponents(url: client.serverRootURL, resolvingAgainstBaseURL: false)
        let isHTTPS = components?.scheme == "https"
        components?.scheme = isHTTPS ? "wss" : "ws"
        components?.path = "/ws/chat"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else { return }
        socket.connect(url: url)
    }

    private func handleSocketEvent(_ event: WSEvent) {
        switch event.type {
        case "hello":
            chatConnection = .connected
            socket.markConnected()
        case "message":
            handleIncomingMessage(event.payload)
        case "ack":
            handleAck(event.payload)
        case "typing":
            if let conversationID = event.payload["conversation_id"] as? String {
                showTyping(conversationID: conversationID)
            }
        case "online_status":
            if let userID = event.payload["user_id"] as? String,
               let online = event.payload["online"] as? Bool {
                if online {
                    onlineUserIDs.insert(userID)
                } else {
                    onlineUserIDs.remove(userID)
                }
            }
        case "match":
            // 新匹配即新会话：刷新会话列表（推荐弹窗由 HTTP like 响应路径负责）
            Task { await loadConversations() }
        default:
            break // read / pong / error：原型阶段无 UI 消费
        }
    }

    /// 对方新消息：多设备自己回执按 id 去重；未知会话刷新列表兜底
    private func handleIncomingMessage(_ payload: [String: Any]) {
        guard let conversationID = payload["conversation_id"] as? String,
              let data = try? JSONSerialization.data(withJSONObject: payload["message"] ?? [:]),
              let message = try? JSONDecoder.chat.decode(MessageResponse.self, from: data)
        else { return }
        guard message.senderId != myUserID else { return } // 自己回执已由乐观插入覆盖
        guard conversations.contains(where: { $0.id == conversationID }) else {
            Task { await loadConversations() }
            return
        }
        appendMessage(to: conversationID, message.chatMessage(myUserID: myUserID))
        typingConversationIDs.remove(conversationID)
    }

    private func handleAck(_ payload: [String: Any]) {
        guard let conversationID = payload["conversation_id"] as? String,
              let clientMsgID = payload["client_msg_id"] as? String,
              let data = try? JSONSerialization.data(withJSONObject: payload["message"] ?? [:]),
              let message = try? JSONDecoder.chat.decode(MessageResponse.self, from: data)
        else { return }
        applyAck(conversationID: conversationID, clientMsgID: clientMsgID, message: message)
    }

    /// ack：把 pending 消息替换为服务端权威数据（id / seq / 时间戳）
    private func applyAck(conversationID: String, clientMsgID: String, message: MessageResponse) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        guard let msgIndex = conversations[index].messages.firstIndex(where: { $0.id == clientMsgID }) else {
            return
        }
        let confirmed = message.chatMessage(myUserID: myUserID)
        conversations[index].messages[msgIndex] = ChatMessage(
            id: confirmed.id,
            isMe: true,
            text: confirmed.text,
            timestamp: confirmed.timestamp,
            seq: confirmed.seq,
            isPending: false
        )
    }

    private func showTyping(conversationID: String) {
        typingConversationIDs.insert(conversationID)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            self?.typingConversationIDs.remove(conversationID)
        }
    }

    /// 追加消息 + 同步会话摘要与时间；自己发送时顺带清未读
    private func appendMessage(to conversationID: String, _ message: ChatMessage) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].messages.append(message)
        conversations[index].lastMessage = message.text
        conversations[index].lastMessageAt = message.timestamp
        if message.isMe {
            conversations[index].unreadCount = 0
        }
    }

    // MARK: 登录流（调用方约定：返回 true 才推进导航）

    /// 发送验证码；成功后记录手机号与开发回显码，由调用方推入验证码页
    func sendSMS(_ phone: String) async -> Bool {
        isSendingCode = true
        authError = nil
        defer { isSendingCode = false }
        do {
            let response = try await authRepository.sendSMS(phone)
            lastSentPhone = phone
            debugCode = response.debugCode
            return true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 验证码校验 → 登录/注册，令牌已在仓库层落 Keychain；成功返回 true 由调用方分流
    func verifyCode(_ code: String, phone: String) async -> Bool {
        isVerifying = true
        authError = nil
        defer { isVerifying = false }
        do {
            let pair = try await authRepository.verify(code, phone: phone)
            isNewUser = pair.isNewUser
            return true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// Apple 登录：identity_token 交后端验签，令牌已在仓库层落 Keychain；成功返回 true 由调用方分流
    func loginWithApple(identityToken: String, nonce: String?) async -> Bool {
        isVerifying = true
        authError = nil
        defer { isVerifying = false }
        do {
            let pair = try await authRepository.loginWithApple(identityToken: identityToken, nonce: nonce)
            isNewUser = pair.isNewUser
            return true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 身份证实名：通过返回 true；失败写 authError 由 VerifyIDView 展示
    func submitIDCard(realName: String, idNumber: String) async -> Bool {
        isVerifying = true
        authError = nil
        defer { isVerifying = false }
        do {
            _ = try await authRepository.verifyIDCard(realName: realName, idNumber: idNumber)
            return true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 人脸活体：通过返回 true；失败写 authError 由 VerifyIDView 展示
    func submitFaceVerification() async -> Bool {
        isVerifying = true
        authError = nil
        defer { isVerifying = false }
        do {
            _ = try await authRepository.verifyFace()
            return true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    /// 登录成功后的分流（短信 / Apple 登录共用）：新用户进实名注册流，老用户直接进主流程
    func routeAfterLogin() {
        if isNewUser {
            // 新注册：栈替换为 login → verifyID，等同原型注册流（codeInput 完成使命出栈）
            authPath = [.login, .verifyID]
        } else {
            // 老用户：进主流程并拉取服务端资料（authPath 在 logout 时重置）
            enterMainAfterLogin()
        }
    }

    func logout() {
        // 异步撤销服务端 refresh token 与推送令牌绑定（均失败不影响本地登出）
        if let token = deviceToken {
            Task { try? await userRepository.deleteDeviceToken(token: token) }
        }
        Task { try? await authRepository.logout() }
        deviceToken = nil
        authRepository.tokens.clear()
        myProfile = MyProfile()
        draft = ProfileDraft()
        recommendations = []
        cardIndex = 0
        isLoadingRecommendations = false
        likedUserIDs = []
        skippedUserIDs = []
        matchUser = nil
        filter = FilterState()
        conversations = []
        historyCursors = [:]
        onlineUserIDs = []
        typingConversationIDs = []
        myUserID = nil
        chatConnection = .idle
        socket.disconnect()
        authPath = []
        lastSentPhone = nil
        debugCode = nil
        isNewUser = false
        authError = nil
        profileError = nil
        homeError = nil
        phase = .onboarding
    }
}
