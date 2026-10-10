//
//  APIError.swift
//  BanBan · 统一 API 错误模型
//
//  对齐后端统一错误体 {"error": {"code": "...", "message": "..."}}
//  （FastAPI 全局 handler：HTTPException 与 RequestValidationError 均已转换）
//

import Foundation

enum APIError: LocalizedError {
    /// URL 构造失败（baseURL 或 path 非法）
    case invalidURL
    /// 网络层失败（无连接 / 超时 / TLS）
    case transport(underlying: Error)
    /// 服务端返回统一错误体（4xx/5xx 均走此分支）
    case server(status: Int, code: String, message: String)
    /// 响应体解析失败
    case decoding(underlying: Error)
    /// 401 且 refresh 失败（需重新登录）
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请求地址无效"
        case .transport:
            return "网络连接失败，请检查网络后重试"
        case .server(_, _, let message):
            return message
        case .decoding:
            return "数据解析失败"
        case .unauthorized:
            return "登录已过期，请重新登录"
        }
    }
}
