import SwiftUI

/// 消息页：聊天列表 + 喜欢我的（空态）
struct MessagesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var path = NavigationPath()
    @State private var selectedTab = 0
    @StateObject private var comingSoon = ComingSoonModel()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                topBar
                tabSegment
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                if selectedTab == 0 {
                    conversationList
                } else {
                    EmptyStateView(
                        icon: "heart.text.square",
                        title: "还没有人喜欢你",
                        subtitle: "去首页寻找志同道合的搭伴伙伴吧"
                    )
                }
            }
            .background(Color.banbanBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .comingSoonAlert(comingSoon)
            .navigationDestination(for: String.self) { conversationID in
                ChatView(conversationID: conversationID)
            }
        }
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack {
            Text("消息")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanForeground)
            Spacer()
            CircleIconButton(icon: "bell", label: "通知") { comingSoon("消息通知") }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 分段切换

    private var tabSegment: some View {
        HStack(spacing: 0) {
            segmentItem(title: "聊天", index: 0)
            segmentItem(title: "喜欢我的", index: 1)
        }
        .padding(4)
        .background(Color.banbanInput.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: BanBanRadius.medium)
                .stroke(Color.banbanBorder, lineWidth: 1)
        )
    }

    private func segmentItem(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(BanBanFont.body)
                .foregroundStyle(isSelected ? Color.banbanPrimaryForeground : Color.banbanMutedForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: BanBanRadius.small)
                        .fill(isSelected ? Color.banbanPrimary : .clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 聊天列表

    private var conversationList: some View {
        ScrollView {
            if appState.conversations.isEmpty {
                EmptyStateView(
                    icon: "message",
                    title: "还没有消息",
                    subtitle: "主动喜欢一位搭伴伙伴，开始聊天吧"
                )
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(appState.conversations) { conversation in
                        Button {
                            path.append(conversation.id)
                        } label: {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - 会话行

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: conversation.user.avatarURL, size: 48, initial: conversation.user.initial)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.user.name)
                        .font(BanBanFont.bodyLarge.weight(.medium))
                        .foregroundStyle(Color.banbanForeground)
                    Spacer()
                    Text(conversation.timeLabel)
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
                HStack {
                    Text(conversation.lastMessage)
                        .font(BanBanFont.body)
                        .foregroundStyle(Color.banbanMutedForeground)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    badge
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var badge: some View {
        if conversation.unreadCount > 0 {
            Text("\(conversation.unreadCount)")
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanErrorForeground)
                .frame(minWidth: 20, minHeight: 20)
                .background(Capsule().fill(Color.banbanError))
        } else if conversation.hasUnreadDot {
            Circle()
                .fill(Color.banbanError)
                .frame(width: 8, height: 8)
        }
    }
}
