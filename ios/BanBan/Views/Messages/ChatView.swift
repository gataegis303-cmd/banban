import SwiftUI

/// 聊天页：自定义头部 + 安全提示 + 消息气泡 + 输入栏
struct ChatView: View {
    let conversationID: String

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @StateObject private var comingSoon = ComingSoonModel()

    private var conversation: Conversation? {
        appState.conversations.first { $0.id == conversationID }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            InfoBanner(
                text: "请勿在初次聊天中透露住址、财产等敏感信息",
                style: .warning
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            messageList
            inputBar
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .comingSoonAlert(comingSoon)
        .onAppear {
            appState.markConversationRead(conversationID)
        }
    }

    // MARK: - 头部

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(icon: "chevron.left", label: "返回") { dismiss() }

            if let user = conversation?.user {
                AvatarView(url: user.avatarURL, size: 40, initial: user.initial)
                Text(user.name)
                    .font(BanBanFont.bodyLarge.weight(.semibold))
                    .foregroundStyle(Color.banbanForeground)
            } else {
                Spacer()
            }

            Spacer()

            NavigationLink {
                SafetyView()
            } label: {
                Text("举报")
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            .buttonStyle(.plain)

            CircleIconButton(icon: "ellipsis", label: "更多") { comingSoon("更多操作") }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.banbanCard)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.banbanBorder.opacity(0.5))
                .frame(height: 0.5)
        }
    }

    // MARK: - 消息列表

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversation?.messages ?? []) { message in
                        MessageRow(
                            message: message,
                            otherInitial: conversation?.user.initial ?? "",
                            otherAvatarURL: conversation?.user.avatarURL
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .task {
                // 等一帧让消息完成布局再滚到底部，避免直接滚动被布局覆盖
                try? await Task.sleep(nanoseconds: 100_000_000)
                if let last = conversation?.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: conversation?.messages.count) { _ in
                if let last = conversation?.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - 输入栏

    private var inputBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("输入消息...", text: $inputText)
                    .font(BanBanFont.bodyLarge)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.banbanInput.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.banbanBorder, lineWidth: 1))
                    .submitLabel(.send)
                    .onSubmit(sendMessage)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.banbanPrimaryForeground)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.banbanPrimary))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.banbanCard)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.banbanBorder.opacity(0.5))
                    .frame(height: 0.5)
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        appState.send(to: conversationID, text: text)
        inputText = ""
    }

}

// MARK: - 消息行

private struct MessageRow: View {
    let message: ChatMessage
    let otherInitial: String
    let otherAvatarURL: URL?

    private var isMe: Bool { message.isMe }

    var body: some View {
        if isMe {
            HStack(alignment: .bottom) {
                Spacer()
                bubble
            }
        } else {
            HStack(alignment: .bottom, spacing: 12) {
                AvatarView(url: otherAvatarURL, size: 36, initial: otherInitial)
                bubble
                Spacer()
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(BanBanFont.bodyLarge)
            .foregroundStyle(isMe ? Color.banbanPrimaryForeground : Color.banbanForeground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: 280, alignment: isMe ? .trailing : .leading)
            .background(isMe ? Color.banbanPrimary : Color.banbanMuted)
            .clipShape(BubbleShape(isMe: isMe))
    }
}

// MARK: - 气泡形状（四角 12，发送者右下 6，接收者左下 6）

struct BubbleShape: Shape {
    let isMe: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r: CGFloat = 12
        let tail: CGFloat = 6
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r))
        // 左上
        p.addArc(center: CGPoint(x: r, y: r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        // 右上
        p.addArc(center: CGPoint(x: w - r, y: r), radius: r,
                 startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        if isMe {
            // 右下（小圆角）
            p.addArc(center: CGPoint(x: w - tail, y: h - tail), radius: tail,
                     startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            // 左下
            p.addArc(center: CGPoint(x: r, y: h - r), radius: r,
                     startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        } else {
            // 右下
            p.addArc(center: CGPoint(x: w - r, y: h - r), radius: r,
                     startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            // 左下（小圆角）
            p.addArc(center: CGPoint(x: tail, y: h - tail), radius: tail,
                     startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }
        p.closeSubpath()
        return p
    }
}
