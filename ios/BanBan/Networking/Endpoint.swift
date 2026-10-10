//
//  Endpoint.swift
//  BanBan · API 端点描述
//
//  描述路径 / 方法 / 请求体 / 是否需要鉴权；JSON 编码在构造时完成，
//  统一 snake_case 转换（与后端 Pydantic 字段对齐）
//  另支持原始二进制体（照片内容上传）与绝对 URL（OSS 直传等），见 contentType / absoluteURL
//

import Foundation

struct Endpoint {
    let method: String
    let path: String
    let body: Data?
    /// true 时 APIClient 注入 Bearer，且 401 时尝试 refresh 后重放
    let requiresAuth: Bool
    /// 非 JSON 请求体的类型（如照片二进制的 image/jpeg）；nil 按 application/json 处理
    let contentType: String?
    /// 绝对 URL（OSS 预签名、已解析的相对 upload_url）；nil 时按 path 拼接 baseURL
    let absoluteURL: URL?

    /// 显式 init：既有工厂调用不传 contentType / absoluteURL 时默认 nil
    init(
        method: String,
        path: String,
        body: Data?,
        requiresAuth: Bool,
        contentType: String? = nil,
        absoluteURL: URL? = nil
    ) {
        self.method = method
        self.path = path
        self.body = body
        self.requiresAuth = requiresAuth
        self.contentType = contentType
        self.absoluteURL = absoluteURL
    }

    /// JSON 编码配置：camelCase 属性 ↔ snake_case 字段（access_token / is_new_user 等）
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    static func post<Body: Encodable>(
        _ path: String,
        body: Body,
        requiresAuth: Bool = false
    ) -> Endpoint {
        Endpoint(
            method: "POST",
            path: path,
            body: try? encoder.encode(body),
            requiresAuth: requiresAuth
        )
    }

    /// 无请求体的 POST（如 logout 可带 body，此重载留给空 body 场景）
    static func post(_ path: String, requiresAuth: Bool = false) -> Endpoint {
        Endpoint(method: "POST", path: path, body: nil, requiresAuth: requiresAuth)
    }

    static func get(_ path: String, requiresAuth: Bool = false) -> Endpoint {
        Endpoint(method: "GET", path: path, body: nil, requiresAuth: requiresAuth)
    }

    static func put<Body: Encodable>(
        _ path: String,
        body: Body,
        requiresAuth: Bool = false
    ) -> Endpoint {
        Endpoint(
            method: "PUT",
            path: path,
            body: try? encoder.encode(body),
            requiresAuth: requiresAuth
        )
    }

    /// 原始二进制 PUT（path 按 baseURL 拼接，如 /me/photos/{id}/content，需鉴权）
    static func put(
        _ path: String,
        rawBody: Data,
        contentType: String,
        requiresAuth: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: "PUT",
            path: path,
            body: rawBody,
            requiresAuth: requiresAuth,
            contentType: contentType
        )
    }

    /// 原始二进制 PUT（绝对 URL，如 OSS 预签名直传，默认不带 Bearer）
    static func put(
        _ url: URL,
        rawBody: Data,
        contentType: String,
        requiresAuth: Bool = false
    ) -> Endpoint {
        Endpoint(
            method: "PUT",
            path: "",
            body: rawBody,
            requiresAuth: requiresAuth,
            contentType: contentType,
            absoluteURL: url
        )
    }

    static func delete(_ path: String, requiresAuth: Bool = false) -> Endpoint {
        Endpoint(method: "DELETE", path: path, body: nil, requiresAuth: requiresAuth)
    }
}
