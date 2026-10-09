//
//  VerifyIDView.swift
//  BanBan · 真实身份认证（三步）
//
//  对应 pages/verify-id.html。
//  mode: .registration（注册语境，back 回登录，完成后 push 权限页）
//        .settings（设置语境「重新实名认证」，完成后 dismiss）
//

import SwiftUI

enum VerifyIDMode {
    case registration
    case settings
}

struct VerifyIDView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let mode: VerifyIDMode

    @State private var idVerified = false
    @State private var faceVerified = false

    private var allVerified: Bool { idVerified && faceVerified }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleIconButton(icon: "chevron.left", label: "返回") {
                dismiss()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("真实身份认证")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                Text("为了平台安全，需要通过以下验证")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                // 1. 手机号验证 —— 已完成
                stepCard(
                    icon: "phone.fill",
                    title: "手机号验证",
                    subtitle: "已完成",
                    badge: nil,
                    isDone: true,
                    isLocked: false
                ) {}

                // 2. 身份证认证
                stepCard(
                    icon: "person.text.rectangle",
                    title: "身份证认证",
                    subtitle: idVerified ? "已完成" : "点击开始认证",
                    badge: idVerified ? nil : "2",
                    isDone: idVerified,
                    isLocked: false
                ) {
                    guard !idVerified else { return }
                    idVerified = true
                }

                // 3. 人脸活体检测 —— 完成身份证后开启
                stepCard(
                    icon: "faceid",
                    title: "人脸活体检测",
                    subtitle: faceVerified ? "已完成" : (idVerified ? "点击开始检测" : "完成身份证后开启"),
                    badge: faceVerified ? nil : "3",
                    isDone: faceVerified,
                    isLocked: !idVerified
                ) {
                    guard idVerified, !faceVerified else { return }
                    faceVerified = true
                }
            }

            InfoBanner(text: "你的身份信息仅用于实名认证，不会展示给其他用户")
                .padding(.top, 20)

            Spacer()

            Group {
                if mode == .settings {
                    PrimaryButton(title: "继续", icon: nil) {
                        dismiss()
                    }
                    .disabled(!allVerified)
                } else {
                    NavigationLink(value: AuthRoute.permissions) {
                        PrimaryButtonLabel(title: "继续")
                    }
                    .disabled(!allVerified)
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
    }

    private func stepCard(
        icon: String,
        title: String,
        subtitle: String,
        badge: String?,
        isDone: Bool,
        isLocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isDone ? Color.banbanSuccess : (isLocked ? Color.banbanMutedForeground : Color.banbanPrimary))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(isDone ? Color.banbanSuccessSubtle : Color.banbanPrimary.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(BanBanFont.bodyLarge.weight(.semibold))
                        .foregroundStyle(Color.banbanForeground)
                    Text(subtitle)
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
                Spacer()
                if let badge, !isDone {
                    Text(badge)
                        .font(BanBanFont.caption.weight(.semibold))
                        .foregroundStyle(Color.banbanPrimary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.banbanPrimary.opacity(0.12)))
                } else if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.banbanSuccess)
                }
            }
            .padding(14)
            .background(Color.banbanCard)
            .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
            .banbanShadow(1)
            .opacity(isLocked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}
