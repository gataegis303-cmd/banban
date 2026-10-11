//
//  LoginView.swift
//  BanBan · 手机号登录
//
//  对应 pages/login.html：+86 分隔组合输入、协议行、验证码按钮（默认禁用）
//  P10 增补第三方登录：Apple 系统授权（防重放 nonce），微信待开放平台资质（ComingSoon 占位）
//

import AuthenticationServices
import CryptoKit
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var phone = ""
    @State private var agreed = false
    /// Apple 授权请求时生成的原始 nonce（原值发后端，token 内带 sha256 摘要）
    @State private var appleNonce: String?
    @StateObject private var comingSoon = ComingSoonModel()

    private var isValid: Bool {
        phone.count == 11 && agreed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleIconButton(icon: "chevron.left", label: "返回") { dismiss() }

            VStack(alignment: .leading, spacing: 8) {
                Text("手机号登录")
                    .font(BanBanFont.h1)
                    .foregroundStyle(Color.banbanForeground)
                Text("未注册手机号验证后将自动创建账号")
                    .font(BanBanFont.body)
                    .foregroundStyle(Color.banbanMutedForeground)
            }
            .padding(.top, 8)

            // +86 组合输入
            HStack(spacing: 12) {
                Text("+86")
                    .font(BanBanFont.bodyLarge)
                    .foregroundStyle(Color.banbanForeground)
                Rectangle()
                    .fill(Color.banbanBorder)
                    .frame(width: 1, height: 20)
                TextField("请输入手机号", text: $phone)
                    .font(BanBanFont.bodyLarge)
                    .foregroundStyle(Color.banbanForeground)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: phone) { newValue in
                        phone = String(newValue.filter(\.isNumber).prefix(11))
                    }
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

            // 协议行
            Button {
                agreed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(agreed ? Color.banbanPrimary : Color.banbanMutedForeground)
                    Text("已阅读并同意《用户协议》和《隐私政策》")
                        .font(BanBanFont.caption)
                        .foregroundStyle(Color.banbanMutedForeground)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            // 发送失败提示（下次点击前置 nil 复位）
            if let authError = appState.authError {
                InfoBanner(text: authError, style: .warning)
                    .padding(.top, 12)
            }

            Spacer()

            PrimaryButton(title: appState.isSendingCode ? "发送中…" : "获取验证码") {
                Task { await sendCode() }
            }
            .disabled(!isValid || appState.isSendingCode)

            // ── 第三方登录（P10）──
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.banbanBorder)
                    .frame(height: 1)
                Text("其他登录方式")
                    .font(BanBanFont.caption)
                    .foregroundStyle(Color.banbanMutedForeground)
                    .fixedSize()
                Rectangle()
                    .fill(Color.banbanBorder)
                    .frame(height: 1)
            }
            .padding(.top, 24)

            // 系统 Apple 按钮（官方黑底样式）：label 版 init 需 iOS 16.4，故用系统样式 + 外部 frame 对齐
            SignInWithAppleButton(.signIn, onRequest: configureAppleRequest, onCompletion: handleAppleCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .padding(.top, 16)

            Button {
                // 微信登录需开放平台 AppID + Universal Link 资质，暂不可用
                comingSoon("微信登录")
            } label: {
                // 中性描边样式（不引入微信品牌色，遵守设计令牌约定）
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("通过微信登录")
                }
                .font(BanBanFont.bodyLarge.weight(.semibold))
                .foregroundStyle(Color.banbanForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.banbanInput.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: BanBanRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: BanBanRadius.medium)
                        .strokeBorder(Color.banbanBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 12)

            HStack(spacing: 4) {
                Text("遇到问题？")
                    .foregroundStyle(Color.banbanMutedForeground)
                Button {
                    comingSoon("联系客服")
                } label: {
                    Text("联系客服")
                        .foregroundStyle(Color.banbanPrimary)
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
            }
            .font(BanBanFont.caption)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Color.banbanBackground)
        .navigationBarBackButtonHidden(true)
        .comingSoonAlert(comingSoon)
        .toolbar {
            // 数字键盘无收起键：提供「完成」按钮兜底
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { hideKeyboard() }
            }
        }
    }

    // MARK: - 动作

    /// 发送验证码；成功由 AppState 记录手机号/回显码，此处推入验证码页
    private func sendCode() async {
        hideKeyboard()
        if await appState.sendSMS(phone) {
            appState.authPath.append(.codeInput)
        }
    }

    // MARK: Apple 登录

    /// 配置授权请求：未同意协议则提示并跳过（系统弹窗仍会弹出，用户取消即可，onCompletion 再次拦截）
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        guard agreed else {
            appState.authError = "请先阅读并同意《用户协议》和《隐私政策》"
            return
        }
        // 防重放：客户端生成随机 nonce，token 内携带其 sha256 摘要，后端比对
        let raw = Self.newNonce()
        appleNonce = raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256Hex(raw)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8),
              let nonce = appleNonce, agreed
        else { return } // 用户取消 / 凭证缺失：静默
        Task {
            if await appState.loginWithApple(identityToken: token, nonce: nonce) {
                appState.routeAfterLogin()
            }
        }
    }

    /// 32 字节随机值的 base64 编码（nonce 原值）
    private static func newNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    /// sha256 摘要的小写十六进制编码（与后端 hashlib.sha256(...).hexdigest() 对齐）
    private static func sha256Hex(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
