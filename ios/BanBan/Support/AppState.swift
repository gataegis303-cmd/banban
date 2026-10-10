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
    @Published var recommendations: [UserProfile] = MockData.recommendations
    @Published var cardIndex = 0
    @Published var likedUserIDs: Set<String> = []
    @Published var skippedUserIDs: Set<String> = []
    @Published var matchUser: UserProfile?
    @Published var pendingChatUserID: String?
    @Published var conversations: [Conversation] = MockData.conversations
    @Published var filter = FilterState()

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

    init(authRepository: AuthRepository = AuthRepository(client: APIClient())) {
        self.authRepository = authRepository
        // 启动恢复：Keychain 有令牌直接进主流程（资料/推荐拉取在 P4 接 bootstrap）
        if authRepository.tokens.hasTokens {
            phase = .main
        }
    }

    var currentCard: UserProfile? {
        guard recommendations.indices.contains(cardIndex) else { return nil }
        return recommendations[cardIndex]
    }

    /// 未读总数：各会话未读求和；「已读但有红点」的会话按 1 计
    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount } + (conversations.contains { $0.hasUnreadDot } ? 1 : 0)
    }

    func completeOnboarding() {
        draft = ProfileDraft()
        phase = .registration
    }

    /// 进入编辑模式：以当前资料全量回填 draft（唯一映射见 ProfileDraft.init(from:)）
    func startEditProfile() {
        draft = ProfileDraft(from: myProfile)
    }

    func completeRegistration() {
        myProfile = MyProfile(from: draft)
        phase = .main
    }

    func saveProfileEdits() {
        myProfile.apply(draft)
    }

    /// 推进卡片：cardIndex 允许等于 count（哨兵位，表示卡片已耗尽），故用 min 兜底
    func advanceCard() {
        cardIndex = min(cardIndex + 1, recommendations.count)
    }

    /// 喜欢：记录 + 推进卡片 + 弹出匹配成功（推进内聚在此，与 skipCurrent 对称）
    func likeCurrent() {
        guard let user = currentCard else { return }
        likedUserIDs.insert(user.id)
        advanceCard()
        matchUser = user
    }

    func skipCurrent() {
        guard let user = currentCard else { return }
        skippedUserIDs.insert(user.id)
        advanceCard()
    }

    /// 匹配成功后进入聊天：无既有会话则新建（id 规则 u-xxx → c-xxx，插入列表首位）
    func ensureConversation(for userID: String) -> String? {
        if let existing = conversations.first(where: { $0.user.id == userID }) {
            return existing.id
        }
        guard let user = recommendations.first(where: { $0.id == userID }) else { return nil }
        let conversationID = userID.replacingOccurrences(of: "u-", with: "c-")
        let conversation = Conversation(
            id: conversationID,
            user: user,
            lastMessage: "",
            timeLabel: "刚刚",
            unreadCount: 0,
            hasUnreadDot: false,
            messages: []
        )
        conversations.insert(conversation, at: 0)
        return conversationID
    }

    func startChatAfterMatch() {
        pendingChatUserID = matchUser?.id
        matchUser = nil
    }

    func dismissMatch() {
        matchUser = nil
    }

    func send(to conversationID: String, text: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].messages.append(ChatMessage(isMe: true, text: text))
        conversations[index].lastMessage = text
        conversations[index].timeLabel = "刚刚"
        conversations[index].unreadCount = 0
        conversations[index].hasUnreadDot = false
    }

    func markConversationRead(_ conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
        conversations[index].hasUnreadDot = false
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

    /// 验证码校验 → 登录/注册，令牌已在仓库层落 Keychain；
    /// 新用户由调用方引导进实名认证（继续注册流），老用户直接进主流程
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

    func logout() {
        // 异步撤销服务端 refresh token（失败不影响本地登出）
        Task { try? await authRepository.logout() }
        authRepository.tokens.clear()
        draft = ProfileDraft()
        cardIndex = 0
        likedUserIDs = []
        skippedUserIDs = []
        matchUser = nil
        filter = FilterState()
        conversations = MockData.conversations
        authPath = []
        lastSentPhone = nil
        debugCode = nil
        isNewUser = false
        authError = nil
        phase = .onboarding
    }
}
