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
    var livingSituation = "独居"
    var petDisplay = "养猫"
    var sleep: SleepHabit = .early
    var matchType = "生活搭子"
    var direction: MatchDirection = .agreement
    var partnerStatus: PartnerStatus = .unmarriedNoPartner
    var seeking: SeekingGender = .opposite
    var noAccept: [String] = ["妈宝", "斤斤计较", "吸烟"]
    var intendedCity = "杭州"
    var parentRelation: ParentRelation = .sameCity
    var financeTrial: FinanceMode = .aa
    var financeFormal: FormalFinanceMode = .aa
    var startTime = "尽快"
    var completion = 85
    var photoCount = 3

    init() {}

    init(from draft: ProfileDraft) {
        merge(draft)
    }

    mutating func apply(_ draft: ProfileDraft) {
        merge(draft)
    }

    private mutating func merge(_ draft: ProfileDraft) {
        if !draft.nickname.isEmpty { nickname = draft.nickname }
        if let g = draft.gender { gender = g }
        if let birthday = draft.birthday {
            let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? age
            age = max(18, years)
        }
        if !draft.city.isEmpty { city = draft.city }
        if !draft.occupation.isEmpty { occupation = draft.occupation }
        if let m = draft.marriage { marriage = m }
        if let s = draft.sleep { sleep = s }
        if draft.pets.contains("猫") { petDisplay = "养猫" }
        else if draft.pets.contains("狗") { petDisplay = "养狗" }
        else if draft.pets.contains("无") { petDisplay = "不养宠" }
        if let d = draft.direction { direction = d }
        if let p = draft.partnerStatus { partnerStatus = p }
        if let s = draft.seeking { seeking = s }
        if !draft.noAccept.isEmpty { noAccept = draft.noAccept }
        if !draft.intendedCity.isEmpty { intendedCity = draft.intendedCity }
        if let p = draft.parentRelation { parentRelation = p }
        if let f = draft.financeTrial { financeTrial = f }
        if let f = draft.financeFormal { financeFormal = f }
        if draft.photoCount > 0 { photoCount = min(draft.photoCount, 6) }
        completion = draft.myProfileCompletion
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
