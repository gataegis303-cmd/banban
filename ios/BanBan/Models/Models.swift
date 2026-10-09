//
//  Models.swift
//  BanBan
//
//  核心数据模型：用户资料（MyProfile / UserProfile）、会话、筛选条件与编辑草稿（ProfileDraft）
//

import Foundation

struct ProfileDraft: Equatable {
    var nickname = ""
    var gender: Gender?
    var birthday: Date?
    var city = ""
    var occupation = ""
    var marriage: MarriageStatus?
    var children: ChildrenStatus?

    var smoking: YesNoSometimes?
    var drinking: YesNoSometimes?
    var sleep: SleepHabit?
    var pets: Set<String> = []

    var direction: MatchDirection?
    var partnerStatus: PartnerStatus?
    var seeking: SeekingGender?
    var livingMode: LivingMode?
    var financeTrial: FinanceMode?
    var financeFormal: FormalFinanceMode?
    var childIntent: ChildIntent?
    var socialBoundary: SocialBoundary?
    var parentRelation: ParentRelation?
    var noAccept: [String] = []
    var intendedCity = ""

    var transportNone = false
    var transportTools: Set<String> = []
    var transportCounts: [String: Int] = [:]
    var taxiMonthlyQuota = ""
    var housingSituation: String?
    var spareRooms = 0
    var housingConditions: Set<String> = []
    var resources: Set<String> = []
    var otherTags: [String] = []
    var photoCount = 0

    static let otherTagLimit = 12

    var myProfileCompletion: Int {
        var score = 40
        if !nickname.isEmpty { score += 10 }
        if gender != nil { score += 5 }
        if !city.isEmpty { score += 5 }
        if !occupation.isEmpty { score += 5 }
        if direction != nil { score += 10 }
        if !noAccept.isEmpty { score += 5 }
        if photoCount >= 3 { score += 15 }
        else if photoCount > 0 { score += 5 }
        return min(score, 100)
    }
}

struct MyProfile: Equatable {
    var nickname = "林夕"
    var age = 32
    var city = "杭州"
    var gender: Gender = .female
    var height = "165cm"
    var education = "本科"
    var occupation = "产品经理"
    var income = "20-30 万"
    var marriage: MarriageStatus = .unmarried
    var birthday: Date?
    var children: ChildrenStatus?
    var livingSituation = "独居"
    var pets: Set<String> = ["猫"]
    var sleep: SleepHabit = .early
    var smoking: YesNoSometimes?
    var drinking: YesNoSometimes?
    var matchType = "生活搭子"
    var direction: MatchDirection = .agreement
    var partnerStatus: PartnerStatus = .unmarriedNoPartner
    var seeking: SeekingGender = .opposite
    var livingMode: LivingMode?
    var childIntent: ChildIntent?
    var socialBoundary: SocialBoundary?
    var noAccept: [String] = ["妈宝", "斤斤计较", "吸烟"]
    var intendedCity = "杭州"
    var parentRelation: ParentRelation = .sameCity
    var financeTrial: FinanceMode = .aa
    var financeFormal: FormalFinanceMode = .aa
    var transportNone = false
    var transportTools: Set<String> = []
    var transportCounts: [String: Int] = [:]
    var taxiMonthlyQuota = ""
    var housingSituation: String?
    var spareRooms = 0
    var housingConditions: Set<String> = []
    var resources: Set<String> = []
    var otherTags: [String] = []
    var startTime = "尽快"
    var completion = 85
    var photoCount = 3

    /// 展示文案由 pets 集合派生（单一数据源，避免猫+狗共存时丢失）
    var petDisplay: String {
        var parts: [String] = []
        if pets.contains("猫") { parts.append("养猫") }
        if pets.contains("狗") { parts.append("养狗") }
        if pets.contains("其他") { parts.append("其他宠物") }
        if parts.isEmpty { return pets.contains("无") ? "不养宠" : "未填写" }
        return parts.joined(separator: "、")
    }

    init() {}

    init(from draft: ProfileDraft) {
        merge(draft)
    }

    mutating func apply(_ draft: ProfileDraft) {
        merge(draft)
    }

    private mutating func merge(_ draft: ProfileDraft) {
        // 文本类：非空才覆盖（避免误清空）
        if !draft.nickname.isEmpty { nickname = draft.nickname }
        if !draft.city.isEmpty { city = draft.city }
        if !draft.occupation.isEmpty { occupation = draft.occupation }
        if !draft.intendedCity.isEmpty { intendedCity = draft.intendedCity }
        // 选择类：选中才覆盖
        if let g = draft.gender { gender = g }
        if let m = draft.marriage { marriage = m }
        if let s = draft.sleep { sleep = s }
        if let d = draft.direction { direction = d }
        if let p = draft.partnerStatus { partnerStatus = p }
        if let s = draft.seeking { seeking = s }
        if let p = draft.parentRelation { parentRelation = p }
        if let f = draft.financeTrial { financeTrial = f }
        if let f = draft.financeFormal { financeFormal = f }
        if let c = draft.children { children = c }
        if let s = draft.smoking { smoking = s }
        if let d = draft.drinking { drinking = d }
        if let l = draft.livingMode { livingMode = l }
        if let c = draft.childIntent { childIntent = c }
        if let s = draft.socialBoundary { socialBoundary = s }
        if let b = draft.birthday {
            birthday = b
            let years = Calendar.current.dateComponents([.year], from: b, to: Date()).year ?? age
            // 18 = 成年下限，防止 mock 数据被编辑出未成年年龄
            age = max(18, years)
        }
        // 6 = 资料照片上限（与产品规格一致）
        if draft.photoCount > 0 { photoCount = min(draft.photoCount, 6) }
        // 集合 / 开关 / 明细类：整体覆盖（编辑模式由 ProfileDraft(from:) 全量回填，清空即有意为之）
        pets = draft.pets
        noAccept = draft.noAccept
        transportNone = draft.transportNone
        transportTools = draft.transportTools
        transportCounts = draft.transportCounts
        taxiMonthlyQuota = draft.taxiMonthlyQuota
        housingSituation = draft.housingSituation
        spareRooms = draft.spareRooms
        housingConditions = draft.housingConditions
        resources = draft.resources
        otherTags = draft.otherTags
        completion = draft.myProfileCompletion
    }
}

extension ProfileDraft {
    /// 编辑模式回填：MyProfile → draft 的唯一映射（新增资料字段需同步 init(from:) 与 MyProfile.merge(_:) 两处）
    init(from profile: MyProfile) {
        self.init()
        nickname = profile.nickname
        gender = profile.gender
        birthday = profile.birthday
        city = profile.city
        occupation = profile.occupation
        marriage = profile.marriage
        children = profile.children
        smoking = profile.smoking
        drinking = profile.drinking
        sleep = profile.sleep
        pets = profile.pets
        direction = profile.direction
        partnerStatus = profile.partnerStatus
        seeking = profile.seeking
        livingMode = profile.livingMode
        financeTrial = profile.financeTrial
        financeFormal = profile.financeFormal
        childIntent = profile.childIntent
        socialBoundary = profile.socialBoundary
        parentRelation = profile.parentRelation
        noAccept = profile.noAccept
        intendedCity = profile.intendedCity
        transportNone = profile.transportNone
        transportTools = profile.transportTools
        transportCounts = profile.transportCounts
        taxiMonthlyQuota = profile.taxiMonthlyQuota
        housingSituation = profile.housingSituation
        spareRooms = profile.spareRooms
        housingConditions = profile.housingConditions
        resources = profile.resources
        otherTags = profile.otherTags
        photoCount = profile.photoCount
    }
}

struct LifestyleItem: Identifiable, Hashable {
    let icon: String
    let label: String
    var id: String { label }
}

struct UserProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let age: Int
    let city: String
    let occupation: String
    let avatarURL: URL?
    let verified: Bool
    let headline: String
    let cardTags: [String]
    let intentionTags: [String]
    let noAccept: [String]
    let lifestyle: [LifestyleItem]
    let aboutMe: String
    let photos: [URL?]

    var initial: String { String(name.prefix(1)) }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let isMe: Bool
    let text: String
}

struct Conversation: Identifiable, Equatable {
    let id: String
    let user: UserProfile
    var lastMessage: String
    var timeLabel: String
    var unreadCount: Int
    var hasUnreadDot: Bool
    var messages: [ChatMessage]
}

struct FilterState: Equatable {
    var city: String?
    var ageRange: ClosedRange<Int> = 20...40
    var direction: MatchDirection?
    var partnerStatus: PartnerStatus?
    var seeking: SeekingGender?
    var livingMode: LivingMode?
    var parentRelation: ParentRelation?
    var financeTrial: FinanceMode?
    var financeFormal: FormalFinanceMode?
    var childIntent: ChildIntent?
    var pets: Set<String> = []
    var noAccept: Set<String> = []

    static let ageBounds = 18...80
    static let cities = ["全部城市", "杭州", "上海", "北京", "深圳", "广州", "成都"]

    var isDefault: Bool { self == FilterState() }
    var cityDisplay: String { city ?? "全部城市" }
}
