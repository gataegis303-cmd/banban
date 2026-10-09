//
//  BanBanTokens.swift
//  BanBan 设计令牌 · 单文件交接版（iOS 15+）
//
//  ⚠️ 勿手改、跟随 CSS 更新：权威来源是 BanBan/colors_and_type.css。
//  修改顺序：CSS → 01-design-tokens.md → 本文件 → 跑校验（04-validation-and-loop.md §1）。
//  禁止反向：不要先改本文件再回头对齐 CSS。
//
//  策略（01 §2）：CSS 级联（:root 浅色 / .dark 深色）用 UIColor(dynamicProvider:) 一比一模拟，
//  原型 18 页均为 <html class="dark">，即深色是默认外观 —— provider 中非 .light 一律取深色分支。
//  动态 UIColor 经 Color(uiColor:) 桥接为 SwiftUI Color，动态性完整保留。
//  不依赖 Asset Catalog，本文件可直接拖入任意 Xcode 工程。
//
//  用法示例：
//      Text("搭伴").font(BanBanFont.h2).foregroundStyle(.banbanForeground)
//      VStack { ... }.padding().background(.banbanCard, in: RoundedRectangle(cornerRadius: BanBanRadius.medium))
//          .banbanShadow(1)
//

import SwiftUI
import UIKit

// MARK: - 基础设施

public extension UIColor {
    /// 解析 "#RRGGBB"（# 前缀可选，大小写不敏感）
    convenience init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        self.init(
            red: CGFloat((int >> 16) & 0xFF) / 255.0,
            green: CGFloat((int >> 8) & 0xFF) / 255.0,
            blue: CGFloat(int & 0xFF) / 255.0,
            alpha: 1
        )
    }
}

public extension Color {
    /// 静态常量用（外观无关色）
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

/// CSS 级联模拟：浅色取 :root，深色取 .dark（默认分支）。
private func banbanDynamicColor(_ light: String, _ dark: String) -> Color {
    Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .light ? UIColor(hex: light) : UIColor(hex: dark)
    }))
}

// MARK: - 语义色（动态，双外观）— 01 §3.1

public enum BanBanColor {
    // 13 个语义别名，浅/深两分支均已解引用为具体 hex
    public static let background = banbanDynamicColor("#FFFFFF", "#000000")
    public static let foreground = banbanDynamicColor("#1D1D1F", "#F5F5F7")
    public static let card = banbanDynamicColor("#FFFFFF", "#1C1C1E")
    public static let cardForeground = banbanDynamicColor("#1D1D1F", "#F5F5F7")
    public static let popover = banbanDynamicColor("#FFFFFF", "#3A3A3C")
    public static let popoverForeground = banbanDynamicColor("#1D1D1F", "#F5F5F7")
    /// 浅 = primary-500，深 = primary-400（深色下提亮一档）
    public static let primary = banbanDynamicColor("#007AFF", "#2E8DFF")
    public static let primaryForeground = banbanDynamicColor("#FFFFFF", "#000000")
    public static let muted = banbanDynamicColor("#F2F2F7", "#1C1C1E")
    /// .dark 覆盖但两分支同值 —— 按 01 §4 保持动态实现，勿改静态
    public static let mutedForeground = banbanDynamicColor("#8E8E93", "#8E8E93")
    public static let border = banbanDynamicColor("#E5E5EA", "#3A3A3C")
    public static let input = banbanDynamicColor("#D1D1D6", "#3A3A3C")
    public static let ring = banbanDynamicColor("#007AFF", "#2E8DFF")

    // MARK: 状态色 — 01 §3.2 / §4
    // 主色与 *-foreground 在 .dark 未覆盖 → 静态常量（忠实沿用浅色值，不臆造深色值）
    // *-subtle 在 .dark 有覆盖 → 动态色

    public static let success = Color(hex: "#34C759")            // Apple system green
    public static let successForeground = Color(hex: "#FFFFFF")  // .dark 未覆盖，沿用浅色
    public static let successSubtle = banbanDynamicColor("#E9F9EE", "#142E1F")

    public static let warning = Color(hex: "#FF9500")            // Apple system orange
    public static let warningForeground = Color(hex: "#1D1D1F")  // 橙底深字，.dark 未覆盖
    public static let warningSubtle = banbanDynamicColor("#FFF2E0", "#33230E")

    public static let error = Color(hex: "#FF3B30")              // Apple system red
    public static let errorForeground = Color(hex: "#FFFFFF")    // .dark 未覆盖，沿用浅色
    public static let errorSubtle = banbanDynamicColor("#FFECEA", "#331513")

    public static let info = Color(hex: "#007AFF")               // Apple system blue
    public static let infoForeground = Color(hex: "#FFFFFF")     // .dark 未覆盖，沿用浅色
    public static let infoSubtle = banbanDynamicColor("#E8F2FF", "#0F2338")
}

// MARK: - SwiftUI 消费入口（.banban* 扩展）— 01 §7

public extension Color {
    static let banbanBackground = BanBanColor.background
    static let banbanForeground = BanBanColor.foreground
    static let banbanCard = BanBanColor.card
    static let banbanCardForeground = BanBanColor.cardForeground
    static let banbanPopover = BanBanColor.popover
    static let banbanPopoverForeground = BanBanColor.popoverForeground
    static let banbanPrimary = BanBanColor.primary
    static let banbanPrimaryForeground = BanBanColor.primaryForeground
    static let banbanMuted = BanBanColor.muted
    static let banbanMutedForeground = BanBanColor.mutedForeground
    static let banbanBorder = BanBanColor.border
    static let banbanInput = BanBanColor.input
    static let banbanRing = BanBanColor.ring
    static let banbanSuccess = BanBanColor.success
    static let banbanSuccessForeground = BanBanColor.successForeground
    static let banbanSuccessSubtle = BanBanColor.successSubtle
    static let banbanWarning = BanBanColor.warning
    static let banbanWarningForeground = BanBanColor.warningForeground
    static let banbanWarningSubtle = BanBanColor.warningSubtle
    static let banbanError = BanBanColor.error
    static let banbanErrorForeground = BanBanColor.errorForeground
    static let banbanErrorSubtle = BanBanColor.errorSubtle
    static let banbanInfo = BanBanColor.info
    static let banbanInfoForeground = BanBanColor.infoForeground
    static let banbanInfoSubtle = BanBanColor.infoSubtle
}

// MARK: - 品牌阶（外观无关，静态）— 01 §3.3

public enum BanBanBrandScale {
    public static let p50 = Color(hex: "#E8F2FF")
    public static let p100 = Color(hex: "#CFE5FF")
    public static let p200 = Color(hex: "#9FCBFF")
    public static let p300 = Color(hex: "#66ABFF")
    public static let p400 = Color(hex: "#2E8DFF")
    public static let p500 = Color(hex: "#007AFF")
    public static let p600 = Color(hex: "#0064D6")
    public static let p700 = Color(hex: "#004FAD")
    public static let p800 = Color(hex: "#003B82")
    public static let p900 = Color(hex: "#00275A")
    public static let p950 = Color(hex: "#001C40")
}

// MARK: - 中性阶（外观无关，静态）— 01 §3.4

public enum BanBanNeutralScale {
    public static let n0 = Color(hex: "#FFFFFF")
    public static let n50 = Color(hex: "#F7F7FA")
    public static let n100 = Color(hex: "#F2F2F7")
    public static let n200 = Color(hex: "#E5E5EA")
    public static let n300 = Color(hex: "#D1D1D6")
    public static let n400 = Color(hex: "#AEAEB2")
    public static let n500 = Color(hex: "#8E8E93")
    public static let n600 = Color(hex: "#6E6E73")
    public static let n700 = Color(hex: "#48484A")
    public static let n800 = Color(hex: "#2C2C2E")
    public static let n900 = Color(hex: "#1D1D1F")
    public static let n950 = Color(hex: "#0A0A0C")
}

// MARK: - 排版（Dynamic Type 语义字型）— 01 §5
// CSS .banban-text-* 基于系统字体栈（-apple-system / PingFang SC），原生端直接用语义字型即可自动跟随 Dynamic Type。

public enum BanBanFont {
    public static let display = Font.system(.largeTitle, design: .default).weight(.semibold)
    public static let h1 = Font.system(.title2, design: .default).weight(.semibold)
    public static let h2 = Font.system(.title3, design: .default).weight(.semibold)
    public static let bodyLarge = Font.body
    public static let body = Font.subheadline
    public static let caption = Font.footnote
    public static let label = Font.footnote.weight(.medium)
}

// MARK: - 圆角 — 01 §6.1

public enum BanBanRadius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 12
    /// 9999 —— 胶囊建议直接用 Capsule()，少用魔法数
    public static let full: CGFloat = 9999
}

// MARK: - 阴影（双外观）— 01 §6.2
//
// CSS 原始值（colors_and_type.css L67-69 / L105-107）：
//   shadow-1 浅: 0 1px 2px rgba(0,0,0,.04), 0 1px 1px rgba(0,0,0,.03)   深: 0 1px 2px rgba(0,0,0,.30)
//   shadow-2 浅: 0 8px 24px -8px rgba(0,0,0,.08), 0 4px 8px -4px rgba(0,0,0,.05)
//   shadow-2 深: 0 8px 24px -8px rgba(0,0,0,.50), 0 4px 8px -4px rgba(0,0,0,.40)
//   shadow-3 浅: 0 24px 64px -12px rgba(0,0,0,.12)                      深: 0 24px 64px -12px rgba(0,0,0,.60)
//
// 折算：radius = CSS blur ÷ 2（iOS 惯例）。Layer 存 CSS 原始值，应用时除以 2。

public enum BanBanShadow {
    public struct Layer {
        public let y: CGFloat       // CSS offset-y
        public let blur: CGFloat    // CSS blur（应用时 ÷2 → radius）
        public let spread: CGFloat  // CSS spread（SwiftUI 无原生对应，见 banbanShadow 注释）
        public let opacity: Double

        public init(y: CGFloat, blur: CGFloat, spread: CGFloat, opacity: Double) {
            self.y = y
            self.blur = blur
            self.spread = spread
            self.opacity = opacity
        }
    }

    /// 返回指定级别的阴影层数组；深色为默认外观
    public static func layers(level: Int, dark: Bool) -> [Layer] {
        switch (level, dark) {
        case (1, false):
            return [Layer(y: 1, blur: 2, spread: 0, opacity: 0.04),
                    Layer(y: 1, blur: 1, spread: 0, opacity: 0.03)]
        case (1, true):
            return [Layer(y: 1, blur: 2, spread: 0, opacity: 0.30)]
        case (2, false):
            return [Layer(y: 8, blur: 24, spread: -8, opacity: 0.08),
                    Layer(y: 4, blur: 8, spread: -4, opacity: 0.05)]
        case (2, true):
            return [Layer(y: 8, blur: 24, spread: -8, opacity: 0.50),
                    Layer(y: 4, blur: 8, spread: -4, opacity: 0.40)]
        case (3, false):
            return [Layer(y: 24, blur: 64, spread: -12, opacity: 0.12)]
        case (3, true):
            return [Layer(y: 24, blur: 64, spread: -12, opacity: 0.60)]
        default:
            return []
        }
    }
}

public struct BanBanShadowModifier: ViewModifier {
    let level: Int
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        let layers = BanBanShadow.layers(level: level, dark: colorScheme == .dark)
        return content
            .compositingGroup()
            .banbanApply(layers: layers)
    }
}

public extension View {
    /// 逐层叠加阴影；radius = CSS blur ÷ 2（01 §6.2）
    /// 注：CSS 负 spread（-8 / -4 / -12）在 SwiftUI 无原生等价，此处忽略
    /// （差异仅为阴影收边范围，深色背景下几乎不可见；如需像素级还原请用 CALayer.shadowPath 自行实现）。
    @ViewBuilder
    func banbanApply(layers: [BanBanShadow.Layer]) -> some View {
        if layers.count >= 2 {
            self
                .shadow(color: .black.opacity(layers[0].opacity),
                        radius: layers[0].blur / 2, x: 0, y: layers[0].y)
                .shadow(color: .black.opacity(layers[1].opacity),
                        radius: layers[1].blur / 2, x: 0, y: layers[1].y)
        } else if let only = layers.first {
            self.shadow(color: .black.opacity(only.opacity),
                        radius: only.blur / 2, x: 0, y: only.y)
        } else {
            self
        }
    }

    /// 消费入口：.banbanShadow(1) / .banbanShadow(2) / .banbanShadow(3)
    func banbanShadow(_ level: Int) -> some View {
        modifier(BanBanShadowModifier(level: level))
    }
}
