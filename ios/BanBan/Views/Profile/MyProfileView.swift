import SwiftUI

/// 我的资料页：头像区 + 资料完成度 + 基础信息 / 生活方式 / 搭伴意向 / 照片墙
struct MyProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var path = NavigationPath()
    @State private var showsEdit = false

    private var profile: MyProfile { appState.myProfile }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    avatarSection
                    completionCard
                        .padding(.horizontal, 20)
                    infoCards
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .background(Color.banbanBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                case .verifyID:
                    VerifyIDView(mode: .settings)
                }
            }
        }
        .fullScreenCover(isPresented: $showsEdit) {
            WizardFlowView(mode: .edit)
        }
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack {
            NavigationLink(value: ProfileRoute.settings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.banbanForeground)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.banbanMuted.opacity(0.6)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("我的资料")
                .font(BanBanFont.h2)
                .foregroundStyle(Color.banbanCardForeground)

            Spacer()

            Button {
                appState.startEditProfile()
                showsEdit = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.banbanPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.banbanMuted.opacity(0.6)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 头像区

    private var avatarSection: some View {
        VStack(spacing: 0) {
            topBar

            VStack(spacing: 4) {
                AvatarView(url: MockData.currentUserAvatar, size: 96, initial: String(profile.nickname.prefix(1)))
                    .overlay(
                        Circle().stroke(Color.banbanPrimary.opacity(0.2), lineWidth: 2)
                    )

                HStack(spacing: 8) {
                    Text(profile.nickname)
                        .font(BanBanFont.h2)
                        .foregroundStyle(Color.banbanCardForeground)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.banbanSuccess)
                }
                .padding(.top, 12)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                        Text(profile.city)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "cake")
                        Text("\(profile.age) 岁")
                    }
                }
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanMutedForeground)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: - 资料完成度

    private var completionCard: some View {
        SectionCard {
            VStack(spacing: 8) {
                HStack {
                    Text("资料完成度")
                        .font(BanBanFont.label)
                        .foregroundStyle(Color.banbanCardForeground)
                    Spacer()
                    Text("\(profile.completion)%")
                        .font(BanBanFont.label)
                        .foregroundStyle(Color.banbanPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.banbanMuted)
                        Capsule()
                            .fill(Color.banbanPrimary)
                            .frame(width: geo.size.width * CGFloat(profile.completion) / 100)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    // MARK: - 资料卡片组

    private var infoCards: some View {
        VStack(spacing: 16) {
            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("基础信息")
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanCardForeground)
                        .padding(.bottom, 6)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 10) {
                        InfoRow(label: "性别", value: profile.gender.rawValue)
                        InfoRow(label: "身高", value: profile.height)
                        InfoRow(label: "学历", value: profile.education)
                        InfoRow(label: "职业", value: profile.occupation)
                        InfoRow(label: "年收入", value: profile.income, showsBorder: false)
                        InfoRow(label: "婚姻状况", value: profile.marriage.rawValue, showsBorder: false)
                    }
                }
            }

            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("生活方式")
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanCardForeground)
                        .padding(.bottom, 6)
                    InfoRow(label: "居住情况", value: profile.livingSituation)
                    InfoRow(label: "是否养宠", value: profile.petDisplay)
                    InfoRow(label: "作息习惯", value: profile.sleep.rawValue, showsBorder: false)
                }
            }

            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("搭伴意向")
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanCardForeground)
                        .padding(.bottom, 6)
                    InfoRow(label: "搭伴类型", value: profile.matchType)
                    InfoRow(label: "搭伴方向", value: profile.direction.rawValue)
                    InfoRow(label: "可接受伴侣状态", value: profile.partnerStatus.rawValue)
                    InfoRow(label: "搭伴对象", value: profile.seeking.rawValue)
                    InfoRow(label: "我不能接受", value: profile.noAccept.joined(separator: "、"))
                    InfoRow(label: "期望城市", value: profile.intendedCity)
                    InfoRow(label: "与父母关系", value: profile.parentRelation.rawValue)
                    InfoRow(label: "试用期财务管理", value: profile.financeTrial.rawValue)
                    InfoRow(label: "正式关系后财务管理", value: profile.financeFormal.rawValue)
                    InfoRow(label: "开始时间", value: profile.startTime, showsBorder: false)
                }
            }

            SectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("照片墙")
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanCardForeground)
                    photoGrid
                }
            }
        }
    }

    // MARK: - 照片墙

    private var photoGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(0..<min(profile.photoCount, 6), id: \.self) { index in
                AsyncImage(url: URL(string: "https://picsum.photos/seed/banban-photo\(index + 1)/600/600")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.banbanMuted
                        Image(systemName: "image")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.banbanMutedForeground)
                    }
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
            }
        }
    }
}

// MARK: - 路由

enum ProfileRoute: Hashable {
    case settings
    case verifyID
}
