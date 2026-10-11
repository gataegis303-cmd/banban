//
//  VerifyIDView.swift
//  BanBan · 真实身份认证（三步）
//
//  对应 pages/verify-id.html。
//  mode: .registration（注册语境，back 回登录，完成后 push 权限页）
//        .settings（设置语境「重新实名认证」，完成后 dismiss）
//
//  实名链路：POST /verification/id-card（二要素核验）→ POST /verification/face（活体）。
//  活体检测当前为 1.5s 模拟动画，生产接第三方活体 SDK 后替换 startFaceScan 内延时。
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
    @State private var showIDForm = false
    @State private var realName = ""
    @State private var idNumber = ""
    @State private var isFaceScanning = false

    private var allVerified: Bool { idVerified && faceVerified }

    /// 姓名 ≥2 个字符（去空格）+ 证号 18 位
    private var isIDFormValid: Bool {
        realName.trimmingCharacters(in: .whitespaces).count >= 2 && idNumber.count == 18
    }

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

                // 2. 身份证认证 —— 点击展开表单
                stepCard(
                    icon: "person.text.rectangle",
                    title: "身份证认证",
                    subtitle: idVerified
                        ? "已完成"
                        : (showIDForm ? "请填写姓名与身份证号" : "点击开始认证"),
                    badge: idVerified ? nil : "2",
                    isDone: idVerified,
                    isLocked: false
                ) {
                    guard !idVerified, !appState.isVerifying else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { showIDForm.toggle() }
                }

                // 身份证表单
                if showIDForm && !idVerified {
                    idFormCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 3. 人脸活体检测 —— 完成身份证后开启
                stepCard(
                    icon: "faceid",
                    title: "人脸活体检测",
                    subtitle: faceVerified
                        ? "已完成"
                        : (isFaceScanning ? "正在检测…" : (idVerified ? "点击开始检测" : "完成身份证后开启")),
                    badge: faceVerified ? nil : "3",
                    isDone: faceVerified,
                    isLocked: !idVerified
                ) {
                    guard idVerified, !faceVerified, !isFaceScanning else { return }
                    startFaceScan()
                }

                // 活体检测进行中
                if isFaceScanning {
                    faceScanCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if let authError = appState.authError {
                InfoBanner(text: authError, style: .warning)
                    .padding(.top, 12)
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
                        PrimaryButtonLabel(title: appState.isVerifying ? "提交中…" : "继续")
                    }
                    .disabled(!allVerified || appState.isVerifying)
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - 身份证表单卡片

    private var idFormCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("信息仅用于公安二要素核验，提交后加密传输")
                .font(BanBanFont.caption)
                .foregroundStyle(Color.banbanMutedForeground)

            TextField("请输入真实姓名", text: $realName)
                .font(BanBanFont.bodyLarge)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.banbanInput.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .strokeBorder(Color.banbanBorder, lineWidth: 1)
                )

            TextField("请输入 18 位身份证号", text: $idNumber)
                .font(BanBanFont.bodyLarge)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.banbanInput.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .strokeBorder(Color.banbanBorder, lineWidth: 1)
                )
                .onChange(of: idNumber) { _, newValue in
                    // 只留数字与 X（大写），截断 18 位
                    idNumber = String(
                        newValue.uppercased().filter { $0.isNumber || $0 == "X" }.prefix(18)
                    )
                }

            PrimaryButton(
                title: appState.isVerifying ? "认证中…" : "开始认证",
                icon: nil
            ) {
                submitIDCard()
            }
            .disabled(!isIDFormValid || appState.isVerifying)
        }
        .padding(14)
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .banbanShadow(1)
    }

    // MARK: - 活体检测中卡片

    private var faceScanCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(Color.banbanPrimary)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("正在活体检测")
                    .font(BanBanFont.bodyLarge.weight(.semibold))
                    .foregroundStyle(Color.banbanForeground)
                Text("请保持面部在取景框内，不要遮挡")
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.banbanCard)
        .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.large))
        .banbanShadow(1)
    }

    // MARK: - 提交逻辑

    private func submitIDCard() {
        guard isIDFormValid, !appState.isVerifying else { return }
        Task {
            let name = realName.trimmingCharacters(in: .whitespaces)
            let success = await appState.submitIDCard(realName: name, idNumber: idNumber)
            if success {
                withAnimation(.easeInOut(duration: 0.2)) { showIDForm = false }
                idVerified = true
            }
        }
    }

    /// 活体检测：1.5s 模拟扫描动画后调用后端。生产接第三方活体 SDK 后替换此处。
    private func startFaceScan() {
        isFaceScanning = true
        appState.authError = nil
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            let success = await appState.submitFaceVerification()
            isFaceScanning = false
            if success {
                faceVerified = true
            }
        }
    }

    // MARK: - 步骤卡片

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
