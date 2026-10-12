//
//  UserRepository.swift
//  BanBan · 我的资料仓库
//
//  对接后端 /me 前缀端点（全部 requiresAuth）：
//  - GET  /me/profile          惰性建行拉取
//  - PUT  /me/profile          增量合并更新（nil 字段 = 不修改）
//  - POST /me/profile/submit   提交完成，服务端重算 completion
//  - 照片：登记（返回 upload_url）→ 二进制直传 → 删除（按 order）→ 重排
//

import Foundation

struct UserRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - 资料

    /// 拉取我的资料（后端惰性建行，首次返回默认值）
    func getProfile() async throws -> ProfileResponse {
        try await client.send(Endpoint.get("/me/profile", requiresAuth: true))
    }

    /// 增量合并更新资料，返回合并后的完整资料
    func updateProfile(_ update: ProfileUpdateRequest) async throws -> ProfileResponse {
        try await client.send(Endpoint.put("/me/profile", body: update, requiresAuth: true))
    }

    /// 提交资料完成向导
    func submitProfile() async throws -> ProfileSubmittedResponse {
        try await client.send(Endpoint.post("/me/profile/submit", requiresAuth: true))
    }

    // MARK: - 照片

    /// 登记照片位 → 二进制直传，一步完成
    /// （P4 仅能力就绪：WizardStep4 仍为本地占位布尔数组，未接选图上传 UI）
    func uploadPhoto(order: Int, contentType: String, data: Data) async throws {
        let registered: PhotoUploadResponse = try await client.send(
            Endpoint.post(
                "/me/photos",
                body: PhotoUploadRequest(order: order, contentType: contentType),
                requiresAuth: true
            )
        )
        let upload = try uploadEndpoint(for: registered.uploadUrl, contentType: contentType, data: data)
        try await client.sendVoid(upload)
    }

    /// upload_url 双形态：
    /// - dev：服务器根相对路径（如 /api/v1/me/photos/{id}/content，已含 /api/v1 前缀，
    ///   须按 serverRootURL 解析，直接拼 baseURL 会双重前缀；带 Bearer）
    /// - 生产：OSS 预签名绝对 URL（直传，不带 Bearer）
    private func uploadEndpoint(for uploadUrl: String, contentType: String, data: Data) throws -> Endpoint {
        if let url = URL(string: uploadUrl), url.scheme != nil {
            return .put(url, rawBody: data, contentType: contentType)
        }
        guard let url = URL(string: uploadUrl, relativeTo: client.serverRootURL) else {
            throw APIError.invalidURL
        }
        return .put(url, rawBody: data, contentType: contentType, requiresAuth: true)
    }

    /// 按照片位 order 删除
    func deletePhoto(order: Int) async throws {
        try await client.sendVoid(Endpoint.delete("/me/photos/\(order)", requiresAuth: true))
    }

    /// 重排照片，返回重排后的照片列表
    func reorderPhotos(_ photoIds: [String]) async throws -> [PhotoResponse] {
        try await client.send(
            Endpoint.put("/me/photos/reorder", body: PhotoReorderRequest(photoIds: photoIds), requiresAuth: true)
        )
    }

    // MARK: - APNs 设备令牌

    /// 上报 APNs 设备令牌（幂等；服务端按 token 全局唯一 upsert，换账号登录时改绑）
    func registerDeviceToken(token: String) async throws {
        try await client.sendVoid(
            Endpoint.put(
                "/me/device-token",
                body: DeviceTokenRequest(token: token, platform: "ios"),
                requiresAuth: true
            )
        )
    }

    /// 注销设备令牌（登出时调用）：凭 token 值删除、无需 Bearer（登出先清 Keychain，带鉴权必 401）
    func deleteDeviceToken(token: String) async throws {
        try await client.sendVoid(
            Endpoint.delete("/me/device-token?token=\(token)", requiresAuth: false)
        )
    }
}
