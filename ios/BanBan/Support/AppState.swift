import SwiftUI

enum AppPhase: Equatable {
    case onboarding
    case registration
    case main
}

enum PreferredScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
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

    var currentCard: UserProfile? {
        guard recommendations.indices.contains(cardIndex) else { return nil }
        return recommendations[cardIndex]
    }

    var hasMoreCards: Bool { cardIndex < recommendations.count }

    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount } + (conversations.contains { $0.hasUnreadDot } ? 1 : 0)
    }

    func completeOnboarding() {
        draft = ProfileDraft()
        phase = .registration
    }

    func startEditProfile() {
        draft = ProfileDraft()
        applyDraftFields(from: myProfile)
    }

    private func applyDraftFields(from profile: MyProfile) {
        draft.nickname = profile.nickname
        draft.gender = profile.gender
        draft.city = profile.city
        draft.occupation = profile.occupation
        draft.marriage = profile.marriage
        draft.sleep = profile.sleep
        draft.direction = profile.direction
        draft.partnerStatus = profile.partnerStatus
        draft.seeking = profile.seeking
        draft.noAccept = profile.noAccept
        draft.intendedCity = profile.intendedCity
        draft.parentRelation = profile.parentRelation
        draft.financeTrial = profile.financeTrial
        draft.financeFormal = profile.financeFormal
        if profile.petDisplay == "养猫" { draft.pets = ["猫"] }
        else if profile.petDisplay == "养狗" { draft.pets = ["狗"] }
        draft.photoCount = profile.photoCount
    }

    func completeRegistration() {
        myProfile = MyProfile(from: draft)
        phase = .main
    }

    func saveProfileEdits() {
        myProfile.apply(draft)
    }

    func advanceCard() {
        cardIndex = min(cardIndex + 1, recommendations.count)
    }

    func likeCurrent() {
        guard let user = currentCard else { return }
        likedUserIDs.insert(user.id)
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

    func logout() {
        draft = ProfileDraft()
        cardIndex = 0
        likedUserIDs = []
        skippedUserIDs = []
        matchUser = nil
        filter = FilterState()
        conversations = MockData.conversations
        phase = .onboarding
    }
}
