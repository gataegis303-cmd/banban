//
//  ChatRepository.swift
//  BanBan · 会话 / 消息仓库
//
//  对接后端（全部 requiresAuth，日期用 ISO8601 带微秒解码）：
//  - GET  /conversations                       会话列表
//  - GET  /conversations/{id}/messages         消息历史（seq 游标分页，旧→新返回）
//  - POST /conversations/{id}/messages         HTTP 兜底发消息（WS 主通道）
//  - POST /conversations/{id}/read             已读清零
//

import Foundation

struct ChatRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchConversations() async throws -> [ConversationResponse] {
        let response: ConversationListResponse = try await client.send(
            Endpoint.get("/conversations", requiresAuth: true)
        )
        return response.items
    }

    /// 消息历史：cursor 为上一次响应的 next_cursor（取更早一页）
    func fetchMessages(
        conversationID: String, cursor: String? = nil, limit: Int = 20
    ) async throws -> MessageListResponse {
        var path = "/conversations/\(conversationID)/messages?limit=\(limit)"
        if let cursor {
            path += "&cursor=\(cursor)"
        }
        return try await client.send(Endpoint.get(path, requiresAuth: true))
    }

    /// HTTP 兜底发消息（WS 断线时调用）
    func sendMessage(
        conversationID: String, content: String, clientMsgID: String
    ) async throws -> MessageResponse {
        try await client.send(
            Endpoint.post(
                "/conversations/\(conversationID)/messages",
                body: ["content": content, "client_msg_id": clientMsgID],
                requiresAuth: true
            )
        )
    }

    func markRead(conversationID: String) async throws {
        try await client.sendVoid(
            Endpoint.post("/conversations/\(conversationID)/read", requiresAuth: true)
        )
    }
}
