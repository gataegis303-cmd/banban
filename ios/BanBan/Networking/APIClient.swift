//
//  APIClient.swift
//  BanBan · HTTP 客户端
//
//  async/await URLSession 封装：
//  send(endpoint) = 组装请求 → 拦截器注入 Bearer → 执行
//                   → 401 时 refresh 换新后重放一次 → 统一错误体解析
//

import Foundation

final class APIClient {
    /// 本地开发指向 Mac 宿主机后端；P13 部署时改为生产域名
    static let defaultBaseURL = URL(string: "http://127.0.0.1:8000/api/v1")!

    private let baseURL: URL
    private let tokenStore: KeychainTokenStore
    private let session: URLSession
    private let interceptor: AuthInterceptor

    init(
        baseURL: URL = APIClient.defaultBaseURL,
        tokenStore: KeychainTokenStore = KeychainTokenStore(),
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = session
        self.interceptor = AuthInterceptor(tokenStore: tokenStore, baseURL: baseURL, session: session)
    }

    var tokens: KeychainTokenStore { tokenStore }

    /// 带鉴权流程的请求入口
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = try interceptor.authorize(endpoint, baseURL: baseURL)
        var (data, response) = try await perform(request)

        if statusCode(response) == 401 && endpoint.requiresAuth {
            // access 过期：刷新成功则重建请求（携带新 token）重放一次
            guard await interceptor.handleUnauthorized() else {
                throw APIError.unauthorized
            }
            request = try interceptor.authorize(endpoint, baseURL: baseURL)
            (data, response) = try await perform(request)
        }

        return try decode(data, response)
    }

    // MARK: - 底层执行

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transport(underlying: error)
        }
    }

    private func statusCode(_ response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? 0
    }

    /// 2xx → 解码；非 2xx → 解析统一错误体 {"error": {"code","message"}} 抛 server
    /// （ErrorBody/Envelope 需文件级声明：类型不能嵌套在泛型函数里）
    private func decode<T: Decodable>(_ data: Data, _ response: URLResponse) throws -> T {
        let status = statusCode(response)
        guard (200..<300).contains(status) else {
            if let envelope = try? JSONDecoder.api.decode(ErrorEnvelope.self, from: data) {
                throw APIError.server(status: status, code: envelope.error.code, message: envelope.error.message)
            }
            throw APIError.server(status: status, code: "http_\(status)", message: "请求失败（\(status)）")
        }
        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }
}

/// 后端统一错误体的 envelope（P1 定稿：HTTPException 与 422 均归一为 {"error":{...}}）
private struct APIErrorBody: Decodable {
    let code: String
    let message: String
}

private struct ErrorEnvelope: Decodable {
    let error: APIErrorBody
}

// MARK: - JSON 解码配置

extension JSONDecoder {
    /// 全局解码策略：snake_case ↔ camelCase（与后端契约对齐）
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
