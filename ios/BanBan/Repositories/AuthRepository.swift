//
//  AuthRepository.swift
//  BanBan · 认证仓库
//
//  短信发送 / 验证登录 / 刷新 / 登出；令牌落 Keychain 由 verify/refresh 内聚处理
//

import Foundation

struct AuthRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// Keychain 令牌存取（AppState 启动恢复登录态 / 登出清理用）
    var tokens: KeychainTokenStore { client.tokens }

    /// 发送验证码；返回服务端 cooldown（秒）与 debugCode（仅开发环境）
    func sendSMS(_ phone: String) async throws -> SmsSendResponse {
        let response: SmsSendResponse = try await client.send(
            .post("/auth/sms/send", body: SmsSendRequest(phone: phone))
        )
        return response
    }

    /// 验证码校验 → 登录/注册；成功后 access/refresh 写入 Keychain
    func verify(_ code: String, phone: String) async throws -> TokenPairResponse {
        let pair: TokenPairResponse = try await client.send(
            .post("/auth/sms/verify", body: SmsVerifyRequest(phone: phone, code: code))
        )
        client.tokens.saveAccess(pair.accessToken)
        client.tokens.saveRefresh(pair.refreshToken)
        return pair
    }

    /// Apple 登录：identity_token 后端验签后登录/注册；成功后 access/refresh 写入 Keychain
    func loginWithApple(identityToken: String, nonce: String?) async throws -> TokenPairResponse {
        let pair: TokenPairResponse = try await client.send(
            .post("/auth/apple/login", body: AppleLoginRequest(identityToken: identityToken, nonce: nonce))
        )
        client.tokens.saveAccess(pair.accessToken)
        client.tokens.saveRefresh(pair.refreshToken)
        return pair
    }

    /// 身份证两要素核验（姓名 + 证号）；通过后服务端推进 verification 状态机
    func verifyIDCard(realName: String, idNumber: String) async throws -> String {
        let response: VerificationResponse = try await client.send(
            .post(
                "/verification/id-card",
                body: IDCardVerifyRequest(realName: realName, idNumber: idNumber),
                requiresAuth: true
            )
        )
        return response.verification
    }

    /// 人脸活体检测结果提交（开发降级直通；生产接金融级实人认证 SDK）
    func verifyFace() async throws -> String {
        let response: VerificationResponse = try await client.send(
            .post("/verification/face", requiresAuth: true)
        )
        return response.verification
    }

    /// 撤销 refresh token（失败静默，本地清令牌即可）
    func logout() async throws {
        if let refresh = client.tokens.readRefresh() {
            let _: OkResponse = try await client.send(
                .post("/auth/logout", body: LogoutRequest(refreshToken: refresh))
            )
        }
    }
}
