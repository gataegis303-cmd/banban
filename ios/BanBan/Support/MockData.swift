//
//  MockData.swift
//  BanBan
//
//  演示用静态数据（P9 起推荐 / 会话 / 消息均来自后端，此处仅剩演示哈希与我的头像占位）
//

import Foundation

enum MockData {
    static let currentUserAvatar = URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80")

    /// 演示用：筛选结果数不查库，用筛选条件的哈希派生 3~28 的稳定伪随机值，保证同一筛选结果一致
    static func filterResultCount(_ filter: FilterState) -> Int {
        guard !filter.isDefault else { return 12 }
        var hash = 17
        hash = hash &* 31 &+ (filter.city?.hashValue ?? 0)
        hash = hash &* 31 &+ filter.ageRange.lowerBound
        hash = hash &* 31 &+ filter.ageRange.upperBound
        hash = hash &* 31 &+ (filter.direction?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.partnerStatus?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.seeking?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.livingMode?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.parentRelation?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.financeTrial?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.financeFormal?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ (filter.childIntent?.rawValue.hashValue ?? 0)
        hash = hash &* 31 &+ filter.pets.count
        hash = hash &* 31 &+ filter.noAccept.count
        return 3 + abs(hash % 26)
    }
}
