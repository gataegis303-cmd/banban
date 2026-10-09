import SwiftUI

/// 资料详情页（首页卡片 push）
struct ProfileDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let user: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    profileHeader
                    intentionCard
                    if !user.noAccept.isEmpty { noAcceptCard }
                    if !user.lifestyle.isEmpty { lifestyleCard }
                    aboutCard
                    photoCard
                }
                .padding(20)
            }

            actionBar
        }
        .background(Color.banbanBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: 顶栏

    private var headerBar: some View {
        HStack {
            CircleIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: 基本信息头

    private var profileHeader: some View {
        HStack(spacing: 16) {
            AvatarView(url: user.avatarURL, size: 112, initial: user.initial)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(user.name)
                        .font(BanBanFont.h2)
                        .foregroundStyle(Color.banbanForeground)
                    if user.verified {
                        VerifiedBadge()
                    }
                }

                Text(metaText)
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            Spacer(minLength: 0)
        }
    }

    private var metaText: String {
        [("\(user.age) 岁"), user.city, user.occupation].joined(separator: " · ")
    }

    // MARK: 搭伴意向

    private var intentionCard: some View {
        SectionCard {
            SectionHeader(icon: "heart.text.square", title: "搭伴意向")
            FlowLayout(spacing: 8) {
                ForEach(user.intentionTags, id: \.self) { tag in
                    Text(tag)
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.banbanPrimary.opacity(0.1)))
                }
            }
        }
    }

    // MARK: 线下不能接受

    private var noAcceptCard: some View {
        SectionCard {
            SectionHeader(icon: "ban", title: "线下不能接受")
            FlowLayout(spacing: 8) {
                ForEach(user.noAccept, id: \.self) { tag in
                    Text(tag)
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.banbanMuted))
                }
            }
        }
    }

    // MARK: 生活方式

    private var lifestyleCard: some View {
        SectionCard {
            SectionHeader(icon: "cup.and.saucer", title: "生活方式")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 12) {
                ForEach(user.lifestyle) { item in
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(Color.banbanPrimary)
                        Text(item.label)
                            .font(BanBanFont.caption)
                            .foregroundStyle(Color.banbanMutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: 关于我

    private var aboutCard: some View {
        SectionCard {
            SectionHeader(icon: "text.quote", title: "关于我")
            Text(user.aboutMe)
                .font(BanBanFont.body)
                .foregroundStyle(Color.banbanForeground)
                .lineSpacing(4)
        }
    }

    // MARK: 照片墙

    private var photoCard: some View {
        SectionCard {
            SectionHeader(icon: "photo.on.rectangle", title: "照片墙")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(user.photos.enumerated()), id: \.offset) { _, photo in
                    AsyncImage(url: photo) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Rectangle().fill(Color.banbanMuted)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                }
            }
        }
    }

    // MARK: 底栏（跳过 / 喜欢 1:1.6）

    private var actionBar: some View {
        HStack(spacing: 12) {
            SecondaryButton(title: "跳过", icon: "xmark") {
                appState.skipCurrent()
                dismiss()
            }
            .layoutPriority(1)

            PrimaryButton(title: "喜欢", icon: "heart.fill") {
                appState.likeCurrent()
                dismiss()
            }
            .layoutPriority(1.6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.banbanCard)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.banbanBorder.opacity(0.6))
                .frame(height: 0.5)
        }
    }
}
