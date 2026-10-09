//
//  Enums.swift
//  BanBan
//
//  资料与筛选的枚举选项（统一实现 OptionEnum，供 SegmentGroup / EnumChipRow 泛型渲染）
//

import Foundation

protocol OptionEnum: Identifiable, CaseIterable, RawRepresentable where RawValue == String {}

extension OptionEnum {
    var id: String { rawValue }
}

enum Gender: String, OptionEnum {
    case male = "男"
    case female = "女"
}

enum MarriageStatus: String, OptionEnum {
    case unmarried = "未婚"
    case divorced = "离异"
}

enum ChildrenStatus: String, OptionEnum {
    case none = "无子女"
    case withMe = "有子女随我"
    case notWithMe = "有子女不随我"
}

enum YesNoSometimes: String, OptionEnum {
    case yes = "是"
    case no = "否"
    case sometimes = "偶尔"
}

enum SleepHabit: String, OptionEnum {
    case early = "早睡早起"
    case late = "晚睡晚起"
    case irregular = "不规律"
}

enum MatchDirection: String, OptionEnum {
    case marriage = "领证结婚"
    case agreement = "协议搭伴"
    case freestyle = "自由式"
}

enum PartnerStatus: String, OptionEnum {
    case unmarriedNoPartner = "未婚无伴侣"
    case hasSameSexPartner = "有同性伴侣"
    case divorced = "离异"
}

enum SeekingGender: String, OptionEnum {
    case opposite = "异性"
    case same = "同性"
    case any = "不限"
}

enum LivingMode: String, OptionEnum {
    case sameRoom = "同居同房"
    case separateRoom = "同居分房"
    case sameCitySeparate = "同城分居"
}

enum FinanceMode: String, OptionEnum {
    case aa = "AA"
    case byIncomeRatio = "按收入比例"
    case caseByCase = "一事一议"
}

enum FormalFinanceMode: String, OptionEnum {
    case aa = "AA"
    case byIncomeRatio = "按收入比例"
    case caseByCase = "一事一议"
    case jointWealth = "共同财富"
}

enum ChildIntent: String, OptionEnum {
    case yes = "是"
    case no = "否"
    case adoption = "领养"
    case uncertain = "不确定"
}

enum SocialBoundary: String, OptionEnum {
    case independent = "保持独立社交"
    case sharedCircle = "共同朋友圈"
    case negotiable = "可商量"
}

enum ParentRelation: String, OptionEnum {
    case liveTogether = "与其同住"
    case sameCity = "同城居住"
    case estranged = "脱离关系"
    case deceased = "父母双亡"
}

enum TagOptions {
    static let pets = ["猫", "狗", "无", "其他"]
    static let negativeNoAccept = ["妈宝", "邋遢", "花心", "冷暴力", "撒谎成性", "控制欲强", "嗜酒嗜赌", "啃老", "斤斤计较"]
    static let neutralNoAccept = ["养宠", "吸烟", "饮酒", "与父母同住", "异地恋", "工作狂"]
    static let transportTools = ["小车", "电动车", "自行车", "打车报销"]
    static let housingSituations = ["在供房", "全款房", "合租房", "独租房"]
    static let housingConditions = ["商品房", "商业别墅", "Loft", "村屋", "地下室", "私家花园", "固定车位"]
    static let resources = ["存款", "稳定收入", "本地户口", "无贷款"]
}
