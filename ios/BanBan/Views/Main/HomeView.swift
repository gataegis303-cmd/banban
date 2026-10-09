import SwiftUI

/// 首页：推荐卡片 + 筛选 + 匹配成功
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var path = NavigationPath()
    @State private var showsFilter = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    if let user = appState.currentCard {
                        HomeCardView(
                            user: user,
                            onOpenDetail: { path.append(user) },
                            onSkip: { appState.skipCurrent() },
                            onLike: { appState.likeCurrent() }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    } else {
                        EmptyStateView(
                            icon: "heart.text.square",
                            title: "暂时没有更多推荐",
                            subtitle: "调整筛选条件，或稍后再来看看"
                        )
                        .padding(.top, 60)
                    }
                }
            }
            .background(Color.banbanBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: UserProfile.self) { user in
                ProfileDetailView(user: user)
            }
            .navigationDestination(for: String.self) { conversationID in
                ChatView(conversationID: conversationID)
            }
        }
        .sheet(isPresented: $showsFilter) {
            FilterView()
        }
        .fullScreenCover(item: $appState.matchUser) { user in
            MatchSuccessView(
                user: user,
                onMessage: {
                    appState.startChatAfterMatch()
                },
                onContinue: {
                    appState.dismissMatch()
                }
            )
        }
        .onChange(of: appState.pendingChatUserID) { newValue in
            guard let userID = newValue else { return }
            if let conversationID = appState.ensureConversation(for: userID) {
                path.append(conversationID)
            }
            appState.pendingChatUserID = nil
        }
    }

    // MARK: 顶栏（城市 + 筛选）

    private var topBar: some View {
        HStack {
            Button {
                showsFilter = true
            } label: {
                HStack(spacing: 4) {
                    Text(appState.filter.cityDisplay)
                        .font(BanBanFont.bodyLarge.weight(.medium))
                        .foregroundStyle(Color.banbanForeground)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.banbanMutedForeground)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            CircleIconButton(icon: "slider.horizontal.3", label: "筛选") {
                showsFilter = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 推荐卡片

struct HomeCardView: View {
    let user: UserProfile
    var onOpenDetail: () -> Void
    var onSkip: () -> Void
    var onLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            photoArea

            VStack(alignment: .leading, spacing: 12) {
                FlowLayout(spacing: 8) {
                    ForEach(user.cardTags, id: \.self) { tag in
                        Text(tag)
                            .font(BanBanFont.caption)
                            .foregroundStyle(Color.banbanForeground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.banbanMuted))
                            .overlay(Capsule().strokeBorder(Color.banbanBorder, lineWidth: 1))
                    }
                }

                Text(user.headline)
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanForeground)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)

            HStack(spacing: 16) {
                actionButton(title: "跳过", icon: "xmark", isPrimary: false, action: onSkip)
                actionButton(title: "喜欢", icon: "heart", isPrimary: true, action: onLike)
            }
            .padding(16)
        }
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .banbanShadow(2)
    }

    // MARK: 照片区（4:5 + 底部渐变 + 基本信息）

    private var photoArea: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: user.avatarURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.banbanMuted)
                        .overlay(
                            Text(user.initial)
                                .font(.system(size: 56, weight: .medium))
                                .foregroundStyle(Color.banbanMutedForeground)
                        )
                }
            }
            .aspectRatio(4 / 5, contentMode: .fill)

            LinearGradient(
                colors: [Color.banbanForeground.opacity(0.6), Color.banbanForeground.opacity(0)],
                startPoint: .bottom,
                endPoint: .center
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.name)
                        .font(BanBanFont.h1)
                        .foregroundStyle(Color.banbanPrimaryForeground)
                    Text("\(user.age)")
                        .font(BanBanFont.bodyLarge)
                        .foregroundStyle(Color.banbanPrimaryForeground.opacity(0.9))
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                    Text(user.city)
                }
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanPrimaryForeground.opacity(0.8))

                if user.verified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                        Text("已认证")
                    }
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanPrimaryForeground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.banbanPrimaryForeground.opacity(0.2)))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenDetail)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 操作按钮

    private func actionButton(title: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
            }
            .font(BanBanFont.bodyLarge.weight(.medium))
            .foregroundStyle(isPrimary ? Color.banbanPrimaryForeground : Color.banbanForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: BanBanRadius.medium)
                    .fill(isPrimary ? Color.banbanPrimary : Color.banbanCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BanBanRadius.medium)
                    .strokeBorder(isPrimary ? Color.clear : Color.banbanBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
