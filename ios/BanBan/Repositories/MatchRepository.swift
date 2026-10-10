//
//  MatchRepository.swift
//  BanBan · 推荐 / 匹配仓库
//
//  对接后端（全部 requiresAuth）：
//  - GET  /recommendations?limit=10   推荐列表（含用户投影）
//  - POST /recommendations/{id}/like  喜欢（双向命中返回 matched + match_id）
//  - POST /recommendations/{id}/skip  跳过
//  匹配列表 / block 端点待 P7+ 消费时再接
//

import Foundation

struct MatchRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 拉取推荐列表，投影解析为 iOS UserProfile（相对 URL 按 serverRootURL 补全）
    func fetchRecommendations(limit: Int = 10) async throws -> [UserProfile] {
        let response: RecommendationListResponse = try await client.send(
            Endpoint.get("/recommendations?limit=\(limit)", requiresAuth: true)
        )
        return response.items.map { $0.user.userProfile(serverRoot: client.serverRootURL) }
    }

    /// 喜欢：双向命中时 matched 为 true（match_id 暂无消费方，P7+ 会话建立用）
    func like(userID: String) async throws -> LikeActionResponse {
        try await client.send(Endpoint.post("/recommendations/\(userID)/like", requiresAuth: true))
    }

    /// 跳过
    func skip(userID: String) async throws {
        try await client.sendVoid(Endpoint.post("/recommendations/\(userID)/skip", requiresAuth: true))
    }
}
