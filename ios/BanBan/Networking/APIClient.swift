//
//  APIClient.swift
//  BanBan · HTTP 客户端
//
//  async/await URLSession 封装：
//  send(endpoint) = 组装请求 → 拦截器注入 Bearer → 执行
//                   → 401 时 refresh 换新后重放一次 → 统一错误体解析
//  sendVoid(endpoint) = 同链路、忽略响应体（照片二进制上传等空 body 200 端点）
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

    /// scheme://host:port（去掉 /api/v1 路径），用于解析后端返回的相对 upload_url
    /// （dev 上传地址形如 /api/v1/me/photos/{id}/content，直接拼 baseURL 会双重前缀）
    var serverRootURL: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = ""
        return components?.url ?? baseURL
    }

    /// 带鉴权流程的请求入口
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await performWithReplay(endpoint)
        return try decode(data, response)
    }

    /// 期望空响应体（200）的请求，如照片二进制内容上传（PUT content 返回空 body）
    func sendVoid(_ endpoint: Endpoint) async throws {
        let (_, response) = try await performWithReplay(endpoint)
        try assertSuccess(Data(), response)
    }

    // MARK: - 底层执行

    /// 执行请求；requiresAuth 且收到 401 时 refresh 换新后重放一次
    private func performWithReplay(_ endpoint: Endpoint) async throws -> (Data, URLResponse) {
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
        return (data, response)
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
        try assertSuccess(data, response)
        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error)
        }
    }

    /// 非 2xx → 解析统一错误体 {"error": {"code","message"}} 抛 server
    private func assertSuccess(_ data: Data, _ response: URLResponse) throws {
        let status = statusCode(response)
        guard (200..<300).contains(status) else {
            if let envelope = try? JSONDecoder.api.decode(ErrorEnvelope.self, from: data) {
                throw APIError.server(status: status, code: envelope.error.code, message: envelope.error.message)
            }
            throw APIError.server(status: status, code: "http_\(status)", message: "请求失败（\(status)）")
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
