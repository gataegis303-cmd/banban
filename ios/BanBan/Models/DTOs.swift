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

// MARK: - 我的资料（与后端 app/schemas/profile.py 一一对应）

/// birthday 序列化：后端 date 输出 "yyyy-MM-dd" 纯文本，
/// JSONDecoder.api 无日期策略，须手动双向转换
enum BirthdayFormat {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func string(_ date: Date) -> String { formatter.string(from: date) }
    static func date(_ string: String) -> Date? { formatter.date(from: string) }
}

/// GET/PUT /me/profile 响应；枚举字段为中文 rawValue 字符串（与后端 Literal 对齐），
/// 由 MyProfile(response:) 统一转 iOS 枚举
struct ProfileResponse: Decodable {
    let age: Int?
    let birthday: String?
    let nickname: String
    let gender: String?
    let city: String
    let height: String
    let education: String
    let occupation: String
    let income: String
    let marriage: String?
    let children: String?
    let livingSituation: String
    let pets: [String]
    let sleep: String?
    let smoking: String?
    let drinking: String?
    let matchType: String
    let direction: String?
    let partnerStatus: String?
    let seeking: String?
    let livingMode: String?
    let childIntent: String?
    let socialBoundary: String?
    let parentRelation: String?
    let financeTrial: String?
    let financeFormal: String?
    let intendedCity: String
    let noAccept: [String]
    let transportNone: Bool
    let transportTools: [String]
    let transportCounts: [String: Int]
    let taxiMonthlyQuota: String
    let housingSituation: String?
    let spareRooms: Int
    let housingConditions: [String]
    let resources: [String]
    let otherTags: [String]
    let headline: String
    let aboutMe: String
    let startTime: String
    let completion: Int
    let profileSubmitted: Bool
    let photos: [PhotoResponse]
}

/// 照片条目（order 0-5；url 未上传完成时为空串）
struct PhotoResponse: Decodable {
    let order: Int
    let url: String
}

/// PUT /me/profile 请求体：全字段缺省 = 不修改（增量合并语义见后端 schemas/profile.py 文件头）
struct ProfileUpdateRequest: Encodable {
    var birthday: String?
    var nickname: String?
    var gender: String?
    var city: String?
    var marriage: String?
    var children: String?
    var livingSituation: String?
    var pets: [String]?
    var sleep: String?
    var smoking: String?
    var drinking: String?
    var matchType: String?
    var direction: String?
    var partnerStatus: String?
    var seeking: String?
    var livingMode: String?
    var childIntent: String?
    var socialBoundary: String?
    var parentRelation: String?
    var financeTrial: String?
    var financeFormal: String?
    var intendedCity: String?
    var noAccept: [String]?
    var transportNone: Bool?
    var transportTools: [String]?
    var transportCounts: [String: Int]?
    var taxiMonthlyQuota: String?
    var housingSituation: String?
    var spareRooms: Int?
    var housingConditions: [String]?
    var resources: [String]?
    var otherTags: [String]?

    /// draft → 增量合并请求。iOS 向导未采集的字段（height/education/income 等）不传 = 不修改；
    /// 文本空串按后端语义 = 不修改，直接透传；集合字段传值（含空）= 整体覆盖
    init(from draft: ProfileDraft) {
        birthday = draft.birthday.map(BirthdayFormat.string)
        nickname = draft.nickname
        gender = draft.gender?.rawValue
        city = draft.city
        marriage = draft.marriage?.rawValue
        children = draft.children?.rawValue
        pets = draft.pets.sorted()
        sleep = draft.sleep?.rawValue
        smoking = draft.smoking?.rawValue
        drinking = draft.drinking?.rawValue
        direction = draft.direction?.rawValue
        partnerStatus = draft.partnerStatus?.rawValue
        seeking = draft.seeking?.rawValue
        livingMode = draft.livingMode?.rawValue
        childIntent = draft.childIntent?.rawValue
        socialBoundary = draft.socialBoundary?.rawValue
        parentRelation = draft.parentRelation?.rawValue
        financeTrial = draft.financeTrial?.rawValue
        financeFormal = draft.financeFormal?.rawValue
        intendedCity = draft.intendedCity
        noAccept = draft.noAccept
        transportNone = draft.transportNone
        transportTools = draft.transportTools.sorted()
        transportCounts = draft.transportCounts
        taxiMonthlyQuota = draft.taxiMonthlyQuota
        housingSituation = draft.housingSituation
        spareRooms = draft.spareRooms
        housingConditions = draft.housingConditions.sorted()
        resources = draft.resources.sorted()
        otherTags = draft.otherTags
    }
}

/// POST /me/profile/submit 响应
struct ProfileSubmittedResponse: Decodable {
    let profileSubmitted: Bool
    let completion: Int
}

/// POST /me/photos 请求体
struct PhotoUploadRequest: Encodable {
    let order: Int
    let contentType: String
}

/// POST /me/photos 响应：登记结果 + 上传目标
/// （upload_url 开发环境为服务器根相对路径，生产为 OSS 预签名绝对 URL）
struct PhotoUploadResponse: Decodable {
    let photoId: String
    let uploadUrl: String
    let ossKey: String
}

/// PUT /me/photos/reorder 请求体：完整有序 photo_id 列表（未列出的保持原相对顺序）
struct PhotoReorderRequest: Encodable {
    let photoIds: [String]
}
