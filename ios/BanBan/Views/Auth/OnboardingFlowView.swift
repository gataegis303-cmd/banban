//
//  OnboardingFlowView.swift
//  BanBan · 启动引导（3 卡轮播）→ 登录 → 实名认证 → 权限
//
//  对应 pages/onboarding.html；导航规格见 dev-handoff/03-interaction-specs.md §3.1
//

import SwiftUI

/// 认证栈内路由
enum AuthRoute: Hashable {
    case login
    case verifyID
    case permissions
}

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var page = 0
    @State private var path = NavigationPath()

    /// 三张引导卡（lucide → SF Symbol 映射）
    private let cards: [(icon: String, title: String, subtitle: String)] = [
        ("heart.text.square", "认真搭伴，不慌不忙",
         "为不婚却希望共同生活的成年人，寻找志同道合的异性伙伴"),
        ("checkmark.shield", "真实身份，安心开始",
         "手机号 + 实名 + 人脸活体三重验证，先认证再匹配"),
        ("slider.horizontal.3", "清晰边界，彼此尊重",
         "同居方式、财务分摊、生育意愿、社交距离，意向前置减少试探")
    ]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(cards.indices, id: \.self) { index in
                        onboardingCard(cards[index])
                            .padding(.horizontal, 24)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 16) {
                    PrimaryButton(title: "开始使用") {
                        path.append(AuthRoute.login)
                    }
                    Button {
                        path.append(AuthRoute.login)
                    } label: {
                        HStack(spacing: 4) {
                            Text("已有账号，")
                                .foregroundStyle(Color.banbanMutedForeground)
                            Text("登录")
                                .foregroundStyle(Color.banbanPrimary)
                                .fontWeight(.semibold)
                        }
                        .font(BanBanFont.body)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Color.banbanBackground)
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .login:
                    LoginView()
                case .verifyID:
                    VerifyIDView(mode: .registration)
                case .permissions:
                    PermissionsView()
                }
            }
        }
    }

    private func onboardingCard(_ card: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: card.icon)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.banbanPrimary)
                .frame(width: 112, height: 112)
                .background(Circle().fill(Color.banbanPrimary.opacity(0.12)))
            VStack(spacing: 12) {
                Text(card.title)
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                    .multilineTextAlignment(.center)
                Text(card.subtitle)
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
