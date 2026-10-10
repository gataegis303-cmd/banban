//
//  AuthInterceptor.swift
//  BanBan · Bearer 注入 + 401 刷新
//
//  职责：
//  1. 为需要鉴权的请求注入 Authorization: Bearer {access}
//  2. 收到 401 时用 refresh 换新 access（独立裸请求，不走拦截器避免递归），
//     成功返回 true 供 APIClient 重放原请求；失败清空令牌，调用方回登录
//
//  并发竞态（多请求同时 401 触发多次 refresh）暂不处理：
//  P2/P4 链路均为单路串行请求，无并发场景；P6/P9 接入推荐与会话后再收敛
//

import Foundation

struct AuthInterceptor {
    let tokenStore: KeychainTokenStore
    let baseURL: URL
    let session: URLSession

    /// 构造带鉴权头的 URLRequest
    func authorize(_ endpoint: Endpoint, baseURL: URL) throws -> URLRequest {
        var request = try plainRequest(endpoint, baseURL: baseURL)
        if endpoint.requiresAuth, let token = tokenStore.readAccess() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// 401 后的刷新判定；刷新成功返回 true（由 APIClient 重建请求重放）
    /// 刷新自身是裸请求（无需鉴权头，refresh token 在 body 中），失败即清令牌
    func handleUnauthorized() async -> Bool {
        guard let refreshToken = tokenStore.readRefresh() else {
            // 无 refresh 可用：清残留 access，直接判失败
            tokenStore.clear()
            return false
        }
        do {
            let request = try plainRequest(
                Endpoint.post("/auth/refresh", body: RefreshRequest(refreshToken: refreshToken)),
                baseURL: baseURL
            )
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                tokenStore.clear()
                return false
            }
            let pair = try JSONDecoder.api.decode(RefreshResponse.self, from: data)
            tokenStore.saveAccess(pair.accessToken)
            return true
        } catch {
            // refresh 失效或网络异常：清空令牌，上层按未登录处理
            tokenStore.clear()
            return false
        }
    }

    /// 不带鉴权头的原始请求（refresh 自身也走这里）
    func plainRequest(_ endpoint: Endpoint, baseURL: URL) throws -> URLRequest {
        // absoluteURL 直传（OSS 预签名、已按 serverRootURL 解析的相对 upload_url），不再拼 baseURL
        let url: URL
        if let absoluteURL = endpoint.absoluteURL {
            url = absoluteURL
        } else {
            // 不用 URL(string:relativeTo:)：endpoint.path 以 / 开头会整体替换 base 路径（/api/v1 丢失）
            let trimmedPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
            guard let composed = URL(string: baseURL.absoluteString + "/" + trimmedPath) else {
                throw APIError.invalidURL
            }
            url = composed
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        if endpoint.body != nil {
            request.setValue(endpoint.contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
