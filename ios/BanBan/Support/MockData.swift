//
//  MockData.swift
//  BanBan
//
//  演示用静态数据：推荐用户、会话与消息（无真实网络请求）
//

import Foundation

enum MockData {
    static let currentUserAvatar = URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80")

    static let anran = UserProfile(
        id: "u-anran",
        name: "安然",
        age: 28,
        city: "杭州",
        occupation: "图书编辑",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80"),
        verified: true,
        headline: "喜欢安静、独立的相处方式，希望找到尊重彼此空间的搭伴伙伴。",
        cardTags: ["同居分房", "AA", "否", "有猫"],
        intentionTags: ["协议搭伴", "离异", "同性", "同居分房", "AA", "共同财富", "否", "接受宠物猫", "保持独立社交", "同城居住"],
        noAccept: ["冷暴力", "花心"],
        lifestyle: [
            LifestyleItem(icon: "ban", label: "不吸烟"),
            LifestyleItem(icon: "wineglass", label: "偶尔饮酒"),
            LifestyleItem(icon: "moon.zzz", label: "早睡早起")
        ],
        aboutMe: "性格偏安静，喜欢阅读和独立空间。期待一段平等、尊重边界的搭伴关系：可以一起吃饭、旅行，也尊重彼此的独处时间。养了一只橘猫，希望对方同样喜欢小动物。生活中注重沟通，遇到问题愿意面对面交流，而不是冷战或逃避。",
        photos: [
            URL(string: "https://picsum.photos/seed/banban1/600/600"),
            URL(string: "https://picsum.photos/seed/banban2/600/600"),
            URL(string: "https://picsum.photos/seed/banban3/600/600")
        ]
    )

    static let chenyu = UserProfile(
        id: "u-chenyu",
        name: "陈屿",
        age: 35,
        city: "杭州",
        occupation: "建筑设计师",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80"),
        verified: true,
        headline: "喜欢徒步和摄影，期待有边界感的同频伙伴。",
        cardTags: ["同城分居", "一事一议", "否", "有狗"],
        intentionTags: ["协议搭伴", "未婚无伴侣", "不限", "同城分居", "一事一议", "按收入比例", "否", "保持独立社交", "同城居住"],
        noAccept: ["嗜酒嗜赌", "撒谎成性"],
        lifestyle: [
            LifestyleItem(icon: "ban", label: "不吸烟"),
            LifestyleItem(icon: "wineglass", label: "不饮酒"),
            LifestyleItem(icon: "sun.horizon", label: "晨型人")
        ],
        aboutMe: "工作稳定，周末喜欢走山路和拍胶片。生活简单，东西不多，家里常收拾。希望找一个能一起规划生活、也能各自留白的人。",
        photos: [
            URL(string: "https://picsum.photos/seed/banban4/600/600"),
            URL(string: "https://picsum.photos/seed/banban5/600/600")
        ]
    )

    static let suli = UserProfile(
        id: "u-suli",
        name: "苏离",
        age: 29,
        city: "杭州",
        occupation: "自由插画师",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop&q=80"),
        verified: false,
        headline: "作息规律，喜欢做饭和看展，想找稳定长期的生活搭子。",
        cardTags: ["协议搭伴", "按收入比例", "偶尔", "无"],
        intentionTags: ["协议搭伴", "未婚无伴侣", "异性", "同居分房", "按收入比例", "一事一议", "领养", "共同朋友圈", "同城居住"],
        noAccept: ["邋遢", "控制欲强"],
        lifestyle: [
            LifestyleItem(icon: "ban", label: "不吸烟"),
            LifestyleItem(icon: "wineglass", label: "偶尔饮酒"),
            LifestyleItem(icon: "moon.zzz", label: "早睡早起")
        ],
        aboutMe: "接稿在家办公，作息比上班族还规律。擅长做饭，周末常去美术馆。想找长期稳定的生活搭子，一起把日子过得有秩序也有趣味。",
        photos: [
            URL(string: "https://picsum.photos/seed/banban6/600/600"),
            URL(string: "https://picsum.photos/seed/banban7/600/600"),
            URL(string: "https://picsum.photos/seed/banban8/600/600")
        ]
    )

    static let heqi = UserProfile(
        id: "u-heqi",
        name: "何栖",
        age: 31,
        city: "杭州",
        occupation: "大学教师",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&auto=format&fit=crop&q=80"),
        verified: true,
        headline: "理性温和，计划两年内定居杭州，期待认真搭伴的人。",
        cardTags: ["领证结婚", "共同财富", "否", "养宠"],
        intentionTags: ["领证结婚", "离异", "异性", "同居同房", "AA", "共同财富", "否", "接受宠物猫", "可商量", "与其同住"],
        noAccept: ["花心", "啃老"],
        lifestyle: [
            LifestyleItem(icon: "ban", label: "不吸烟"),
            LifestyleItem(icon: "wineglass", label: "偶尔饮酒"),
            LifestyleItem(icon: "moon.zzz", label: "早睡早起")
        ],
        aboutMe: "高校任教，假期固定，生活节奏平稳。做事讲计划，感情上认同搭伴先行。希望遇到同样认真对待生活的人。",
        photos: [
            URL(string: "https://picsum.photos/seed/banban9/600/600"),
            URL(string: "https://picsum.photos/seed/banban10/600/600")
        ]
    )

    static let recommendations: [UserProfile] = [anran, chenyu, suli, heqi]

    static let linxi = UserProfile(
        id: "u-linxi",
        name: "林夕",
        age: 30,
        city: "杭州",
        occupation: "心理咨询师",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80"),
        verified: true,
        headline: "好的，那我们先从朋友开始了解吧。",
        cardTags: [],
        intentionTags: [],
        noAccept: [],
        lifestyle: [],
        aboutMe: "",
        photos: []
    )

    static let zhoumu = UserProfile(
        id: "u-zhoumu",
        name: "周牧",
        age: 33,
        city: "杭州",
        occupation: "咖啡店主",
        avatarURL: URL(string: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&auto=format&fit=crop&q=80"),
        verified: false,
        headline: "我已发送搭伴意向，方便时看看。",
        cardTags: [],
        intentionTags: [],
        noAccept: [],
        lifestyle: [],
        aboutMe: "",
        photos: []
    )

    static var conversations: [Conversation] {
        [
            Conversation(
                id: "c-anran",
                user: anran,
                lastMessage: "周末要不要一起去西湖边走走？",
                timeLabel: "14:32",
                unreadCount: 2,
                hasUnreadDot: false,
                messages: [
                    ChatMessage(isMe: false, text: "你好，看了你的资料，想多了解一下。"),
                    ChatMessage(isMe: true, text: "你好呀，可以聊聊生活习惯。"),
                    ChatMessage(isMe: false, text: "周末要不要一起去西湖边走走？")
                ]
            ),
            Conversation(
                id: "c-linxi",
                user: linxi,
                lastMessage: "好的，那我们先从朋友开始了解吧。",
                timeLabel: "昨天",
                unreadCount: 0,
                hasUnreadDot: true,
                messages: [
                    ChatMessage(isMe: true, text: "你好，很高兴认识你，看了你的搭伴意向觉得挺合的。"),
                    ChatMessage(isMe: false, text: "好的，那我们先从朋友开始了解吧。")
                ]
            ),
            Conversation(
                id: "c-zhoumu",
                user: zhoumu,
                lastMessage: "我已发送搭伴意向，方便时看看。",
                timeLabel: "周一",
                unreadCount: 0,
                hasUnreadDot: false,
                messages: [
                    ChatMessage(isMe: false, text: "我已发送搭伴意向，方便时看看。")
                ]
            )
        ]
    }

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
