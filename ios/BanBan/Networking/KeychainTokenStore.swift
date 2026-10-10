//
//  KeychainTokenStore.swift
//  BanBan · 令牌持久化（Keychain）
//
//  access / refresh 分两个 account 存储；
//  kSecAttrAccessible = afterFirstUnlockThisDeviceOnly（不随备份迁移，锁屏时不可写）
//

import Foundation
import Security

struct KeychainTokenStore {
    private let service: String
    private let accessAccount = "access_token"
    private let refreshAccount = "refresh_token"

    init(service: String = "com.banban.app.token") {
        self.service = service
    }

    // MARK: - 对外接口

    var hasTokens: Bool {
        read(accessAccount) != nil
    }

    func readAccess() -> String? {
        read(accessAccount)
    }

    func readRefresh() -> String? {
        read(refreshAccount)
    }

    func saveAccess(_ token: String) {
        set(accessAccount, value: token)
    }

    func saveRefresh(_ token: String) {
        set(refreshAccount, value: token)
    }

    /// 退出登录 / refresh 失败时清空全部令牌
    func clear() {
        delete(accessAccount)
        delete(refreshAccount)
    }

    // MARK: - Keychain 底层操作

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func set(_ account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        // 已存在则更新，否则新增（Keychain 不支持 upsert）
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery(account: account) as CFDictionary, update as CFDictionary)
        guard status == errSecItemNotFound else {
            if status != errSecSuccess {
                assertionFailure("Keychain 更新失败: \(status)")
            }
            return
        }
        var add = baseQuery(account: account)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        if addStatus != errSecSuccess {
            assertionFailure("Keychain 写入失败: \(addStatus)")
        }
    }

    private func read(_ account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(_ account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }
}
