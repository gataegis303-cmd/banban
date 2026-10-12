//
//  FilterRepository.swift
//  BanBan · 筛选条件仓库
//
//  对接后端（全部 requiresAuth）：
//  - GET /me/filter  读取筛选（首次调用惰性建行，返回默认值）
//  - PUT /me/filter  全量覆盖保存
//

import Foundation

struct FilterRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 读取服务端筛选并解析为本地 FilterState（未知枚举值容错回落不限）
    func fetchFilter() async throws -> FilterState {
        let response: FilterResponse = try await client.send(
            Endpoint.get("/me/filter", requiresAuth: true)
        )
        return FilterState(response: response)
    }

    /// 全量覆盖保存筛选
    func saveFilter(_ state: FilterState) async throws {
        try await client.sendVoid(
            Endpoint.put("/me/filter", body: state.request, requiresAuth: true)
        )
    }
}
