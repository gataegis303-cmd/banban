//
//  DTOs.swift
//  BanBan · 服务端 JSON Codable 映射
//
//  与后端 app/schemas/auth.py 一一对应；snake_case ↔ camelCase
//  由 JSONDecoder/Encoder 的 key 转换策略统一处理，无需逐字段 CodingKeys
//

import Foundation

// MARK: - 短信验证码

/// POST /auth/sms/send 请求体
struct SmsSendRequest: Encodable {
    let phone: String
}

/// POST /auth/sms/send 响应（debugCode 仅后端 APP_DEBUG=true 时返回，生产恒为 nil）
struct SmsSendResponse: Decodable {
    let cooldown: Int
    let debugCode: String?
}

/// POST /auth/sms/verify 请求体
struct SmsVerifyRequest: Encodable {
    let phone: String
    let code: String
}

// MARK: - 登录 / 注册

/// POST /auth/sms/verify 响应：token 对 + 用户摘要
struct TokenPairResponse: Decodable {
    let accessToken: String
    let tokenType: String
    /// access 有效期（秒，后端 15 分钟 = 900）
    let expiresIn: Int
    let refreshToken: String
    /// true = 本次注册新用户（引导进注册流）；false = 老用户直接进主流程
    let isNewUser: Bool
    let user: UserInfo
}

/// 用户摘要（id 为服务端 UUID 字符串）
struct UserInfo: Decodable {
    let id: String
    let phone: String?
    /// pending / phone_verified / id_verified / face_verified / complete
    let verification: String
    let hasProfile: Bool
}

// MARK: - 刷新 / 登出

/// POST /auth/refresh 请求体
struct RefreshRequest: Encodable {
    let refreshToken: String
}

/// POST /auth/refresh 响应（不轮换 refresh）
struct RefreshResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}

/// POST /auth/logout 请求体
struct LogoutRequest: Encodable {
    let refreshToken: String
}

/// 通用成功响应 {"ok": true}
struct OkResponse: Decodable {
    let ok: Bool
}
