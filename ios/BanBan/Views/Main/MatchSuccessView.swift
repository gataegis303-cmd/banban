import SwiftUI

/// 匹配成功（fullScreenCover）
struct MatchSuccessView: View {
    @EnvironmentObject var appState: AppState
    let user: UserProfile
    var onMessage: () -> Void
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.banbanBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 双头像 + 心形徽章 + sparkle 装饰
                ZStack {
                    HStack(spacing: -24) {
                        AvatarView(url: MockData.currentUserAvatar, size: 112, initial: "我")
                            .zIndex(0)
                        AvatarView(url: user.avatarURL, size: 112, initial: user.initial)
                            .zIndex(1)
                    }

                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(BanBanColor.warning)
                        .offset(x: -86, y: -66)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.banbanPrimary.opacity(0.6))
                        .offset(x: 92, y: -40)

                    heartBadge
                }

                Text("匹配成功！")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                    .padding(.top, 32)

                Text("你们互相喜欢，现在可以开始聊聊了")
                    .font(BanBanFont.bodyLarge)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .padding(.top, 12)

                // 对方名牌胶囊
                HStack(spacing: 6) {
                    AvatarView(url: user.avatarURL, size: 24, initial: user.initial)
                    Text("\(user.name) · \(user.age) 岁")
                        .font(BanBanFont.body.weight(.medium))
                        .foregroundStyle(Color.banbanForeground)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.banbanCard))
                .overlay(Capsule().strokeBorder(Color.banbanBorder, lineWidth: 1))
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "发消息", icon: "message.fill") { onMessage() }
                    SecondaryButton(title: "继续浏览", icon: "arrow.right") { onContinue() }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    /// 交界处心形徽章（48 圆 primary 底）
    private var heartBadge: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.banbanPrimaryForeground)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Color.banbanPrimary))
            .overlay(Circle().strokeBorder(Color.banbanBackground, lineWidth: 4))
            .offset(x: -10, y: 6)
    }
}
