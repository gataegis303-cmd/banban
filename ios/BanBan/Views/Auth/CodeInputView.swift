//
//  CodeInputView.swift
//  BanBan · 短信验证码输入
//
//  验证码页原型未覆盖（pages/login.html 只到「获取验证码」），
//  风格对齐 LoginView：脱敏手机号、6 位验证码、60s 倒计时重发、错误横幅
//

import SwiftUI

struct CodeInputView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var countdown = 0
    @State private var countdownTask: Task<Void, Never>?

    private var isValid: Bool {
        code.count == 6
    }

    /// 脱敏手机号：138****1234
    private var maskedPhone: String {
        guard let phone = appState.lastSentPhone, phone.count == 11 else { return "" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleIconButton(icon: "chevron.left", label: "返回") { dismiss() }

            VStack(alignment: .leading, spacing: 8) {
                Text("输入验证码")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                Text("验证码已发送至 \(maskedPhone)")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            .padding(.top, 8)

            // 6 位验证码输入（居中 + 宽字距模拟分离格）
            TextField("请输入验证码", text: $code)
                .font(BanBanFont.h1)
                .foregroundStyle(Color.banbanForeground)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .tracking(8)
                .onChange(of: code) { newValue in
                    code = String(newValue.filter(\.isNumber).prefix(6))
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.banbanInput.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .strokeBorder(Color.banbanBorder, lineWidth: 1)
                )
                .padding(.top, 32)

            // 开发环境验证码回显（后端 APP_DEBUG=true 才下发）
            if let debugCode = appState.debugCode {
                InfoBanner(text: "开发环境验证码：\(debugCode)", style: .info)
                    .padding(.top, 12)
            }

            // 发送 / 校验失败的错误提示（视图展示后由下次动作前置 nil 复位）
            if let authError = appState.authError {
                InfoBanner(text: authError, style: .warning)
                    .padding(.top, 12)
            }

            Spacer()

            PrimaryButton(title: appState.isVerifying ? "验证中…" : "验证并登录") {
                Task { await verify() }
            }
            .disabled(!isValid || appState.isVerifying)

            Button {
                Task { await resend() }
            } label: {
                Text(countdown > 0 ? "重新发送（\(countdown)s）" : "重新发送验证码")
                    .foregroundStyle(countdown > 0 ? Color.banbanMutedForeground : Color.banbanPrimary)
                    .fontWeight(countdown > 0 ? .regular : .medium)
            }
            .buttonStyle(.plain)
            .disabled(countdown > 0 || appState.isSendingCode)
            .font(BanBanFont.caption)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 数字键盘无收起键：提供「完成」按钮兜底
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { hideKeyboard() }
            }
        }
        .onAppear { startCountdown() }
        .onDisappear { countdownTask?.cancel() }
    }

    // MARK: - 动作

    private func verify() async {
        hideKeyboard()
        guard let phone = appState.lastSentPhone else { return }
        if await appState.verifyCode(code, phone: phone) {
            if appState.isNewUser {
                // 新注册：栈替换为 login → verifyID，等同原型注册流（codeInput 完成使命出栈）
                appState.authPath = [.login, .verifyID]
            } else {
                // 老用户：进主流程并拉取服务端资料（authPath 在 logout 时重置）
                appState.enterMainAfterLogin()
            }
        }
    }

    private func resend() async {
        guard let phone = appState.lastSentPhone else { return }
        if await appState.sendSMS(phone) {
            startCountdown()
        }
    }

    /// 60s 倒计时：进页 / 重发成功时启动
    private func startCountdown() {
        countdownTask?.cancel()
        countdown = 60
        countdownTask = Task {
            while !Task.isCancelled && countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { countdown -= 1 }
            }
        }
    }
}
