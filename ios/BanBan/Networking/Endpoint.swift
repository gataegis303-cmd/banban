//
//  Endpoint.swift
//  BanBan · API 端点描述
//
//  描述路径 / 方法 / 请求体 / 是否需要鉴权；JSON 编码在构造时完成，
//  统一 snake_case 转换（与后端 Pydantic 字段对齐）
//

import Foundation

struct Endpoint {
    let method: String
    let path: String
    let body: Data?
    /// true 时 APIClient 注入 Bearer，且 401 时尝试 refresh 后重放
    let requiresAuth: Bool

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
}
