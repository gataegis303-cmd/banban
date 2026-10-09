# 01 设计令牌映射说明（CSS ↔ Swift）

> 权威来源：`../colors_and_type.css`。本文档与 `Tokens/BanBanTokens.swift` 从该文件机械导出，三方必须保持一致（校验脚本 v22 检查 21 抽查关键色值锚点）。

## 1. 令牌权威来源

- **CSS 文件**：`BanBan/colors_and_type.css`（161 行）。`:root` 定义品牌阶、中性阶、状态色、语义别名（浅色基准）、圆角、阴影、字体栈、safe-area；`.dark` 块覆盖语义别名与状态 subtle 底色为深色值。
- **更新方向**：CSS → 本文档 → Swift。CSS 改动后，先更新本文档表格，再同步 `BanBanTokens.swift`，最后跑校验（见 04）。禁止反向：不要先改 Swift 再回头找 CSS 对齐。
- **命名空间**：CSS 令牌前缀 `--banban-*`；Swift 以 `BanBan` 命名空间组织（枚举 `BanBanColor` / `BanBanBrandScale` / `BanBanNeutralScale` / `BanBanRadius` / `BanBanFont` / `BanBanShadow`）。

## 2. 双外观策略：CSS 级联 → UIColor(dynamicProvider:)

CSS 的外观机制是级联覆盖：`:root` 给出浅色基准，`.dark` 覆盖其中一部分为深色值。原型 18 页均为 `<html class="dark">`，即**深色是默认渲染外观**。

Swift 侧用 `UIColor(dynamicProvider:)` 一比一模拟该级联：

```swift
UIColor { trait in
    trait.userInterfaceStyle == .light ? UIColor(hex: lightValue) : UIColor(hex: darkValue)
}
```

- 深色分支值取自 `.dark` 块；浅色分支值取自 `:root` 语义别名区（别名指向的基础色已解引用为具体 hex）。
- `Color(uiColor:)` 桥接为 SwiftUI `Color`，动态性完整保留，跟随系统外观实时切换。
- 不依赖 Asset Catalog，单文件即可拖入任意 Xcode 工程。

## 3. 颜色映射总表

### 3.1 语义色（动态色，双外观）

| 语义令牌 | CSS 变量 | 浅色（`:root`） | 深色（`.dark`，默认） | SwiftUI 消费 |
| --- | --- | --- | --- | --- |
| background | `--banban-background` | `#FFFFFF` | `#000000` | `.banbanBackground` |
| foreground | `--banban-foreground` | `#1D1D1F` | `#F5F5F7` | `.banbanForeground` |
| card | `--banban-card` | `#FFFFFF` | `#1C1C1E` | `.banbanCard` |
| cardForeground | `--banban-card-foreground` | `#1D1D1F` | `#F5F5F7` | `.banbanCardForeground` |
| popover | `--banban-popover` | `#FFFFFF` | `#3A3A3C` | `.banbanPopover` |
| popoverForeground | `--banban-popover-foreground` | `#1D1D1F` | `#F5F5F7` | `.banbanPopoverForeground` |
| primary | `--banban-primary` | `#007AFF`（primary-500） | `#2E8DFF`（primary-400） | `.banbanPrimary` |
| primaryForeground | `--banban-primary-foreground` | `#FFFFFF` | `#000000` | `.banbanPrimaryForeground` |
| muted | `--banban-muted` | `#F2F2F7` | `#1C1C1E` | `.banbanMuted` |
| mutedForeground | `--banban-muted-foreground` | `#8E8E93` | `#8E8E93`（同值） | `.banbanMutedForeground` |
| border | `--banban-border` | `#E5E5EA` | `#3A3A3C` | `.banbanBorder` |
| input | `--banban-input` | `#D1D1D6` | `#3A3A3C` | `.banbanInput` |
| ring | `--banban-ring` | `#007AFF` | `#2E8DFF` | `.banbanRing` |

### 3.2 状态色（反馈与提示）

| 语义令牌 | 浅色（`:root`） | 深色（`.dark`） | 说明 |
| --- | --- | --- | --- |
| success | `#34C759` | 同值（未覆盖） | Apple system green |
| successForeground | `#FFFFFF` | **沿用浅色值** | `.dark` 未覆盖 |
| successSubtle | `#E9F9EE` | `#142E1F` | 深色为暗调底 |
| warning | `#FF9500` | 同值（未覆盖） | Apple system orange |
| warningForeground | `#1D1D1F` | **沿用浅色值** | 橙底深字，`.dark` 未覆盖 |
| warningSubtle | `#FFF2E0` | `#33230E` | 深色为暗调底 |
| error | `#FF3B30` | 同值（未覆盖） | Apple system red |
| errorForeground | `#FFFFFF` | **沿用浅色值** | `.dark` 未覆盖 |
| errorSubtle | `#FFECEA` | `#331513` | 深色为暗调底 |
| info | `#007AFF` | 同值（未覆盖） | Apple system blue |
| infoForeground | `#FFFFFF` | **沿用浅色值** | `.dark` 未覆盖 |
| infoSubtle | `#E8F2FF` | `#0F2338` | 深色为暗调底 |

> **披露**：状态主色与 `*-foreground` 在 `.dark` 中没有覆盖值，原型里它们从未以深色外观重新渲染过（18 页默认即深色，`:root` 浅色值从未真实上屏）。Swift 按级联事实忠实沿用浅色值。如后续在浅色外观下发现对比度问题，应回到 CSS 调整后三方同步。

### 3.3 品牌阶（外观无关，静态常量）

| 阶 | 值 | | 阶 | 值 |
| --- | --- | --- | --- | --- |
| primary-50 | `#E8F2FF` | | primary-600 | `#0064D6` |
| primary-100 | `#CFE5FF` | | primary-700 | `#004FAD` |
| primary-200 | `#9FCBFF` | | primary-800 | `#003B82` |
| primary-300 | `#66ABFF` | | primary-900 | `#00275A` |
| primary-400 | `#2E8DFF` | | primary-950 | `#001C40` |
| primary-500 | `#007AFF` | | | |

Swift：`BanBanBrandScale.p50 … p950`（`Color` 静态常量）。

### 3.4 中性阶（外观无关，静态常量）

| 阶 | 值 | | 阶 | 值 |
| --- | --- | --- | --- | --- |
| neutral-0 | `#FFFFFF` | | neutral-500 | `#8E8E93` |
| neutral-50 | `#F7F7FA` | | neutral-600 | `#6E6E73` |
| neutral-100 | `#F2F2F7` | | neutral-700 | `#48484A` |
| neutral-200 | `#E5E5EA` | | neutral-800 | `#2C2C2E` |
| neutral-300 | `#D1D1D6` | | neutral-900 | `#1D1D1F` |
| neutral-400 | `#AEAEB2` | | neutral-950 | `#0A0A0C` |

Swift：`BanBanNeutralScale.n0 … n950`（`Color` 静态常量）。

## 4. 级联沿用规则（.dark 未覆盖项的处理）

`.dark` 块**只覆盖**以下令牌：background / foreground / card / card-foreground / popover / popover-foreground / primary / primary-foreground / muted / muted-foreground / border / input / ring / 四个 `*-subtle` / 三个阴影。

其余令牌（品牌阶、中性阶、状态主色、状态 `*-foreground`）不分外观。据此 Swift 侧分两类：

1. **动态色**（`dynamic(dark:light:)`）：上表 3.1 全部 + 3.2 的四个 `*-subtle`。
2. **静态常量**：品牌阶、中性阶、状态主色、状态 `*-foreground`。

> mutedForeground 虽在 `.dark` 覆盖清单里，但两分支同为 `#8E8E93`（见 3.1 表），仍按**动态色**实现（`dynamic(dark:light:)` 传同值）——与上面判别口诀一致，不要改为静态常量。

> 判别口诀：`.dark` 块里有 → 动态（即使两分支同值）；`.dark` 块里没有 → 静态。不要凭感觉给未覆盖项补深色值。

## 5. 排版映射表（Dynamic Type 优先）

CSS 基础排版类 `--banban-font-sans` = `-apple-system, "SF Pro", "PingFang SC"…`，iOS 原生即系统字体，无需搬运字体栈。

| CSS 类 | 字号 / 字重 | 行高 | SwiftUI 映射（语义字型，自动跟随 Dynamic Type） |
| --- | --- | --- | --- |
| `.banban-text-display` | clamp(32px, 8vw, 48px) / 600 | 1.1 | `Font.system(.largeTitle, design: .default).weight(.semibold)` |
| `.banban-text-h1` | clamp(24px, 6vw, 32px) / 600 | 1.2 | `Font.system(.title2, design: .default).weight(.semibold)` |
| `.banban-text-h2` | 20px / 600 | 1.3 | `Font.system(.title3, design: .default).weight(.semibold)` |
| `.banban-text-body-large` | 17px / 400 | 1.55 | `Font.body`（17pt） |
| `.banban-text-body` | 15px / 400 | 1.6 | `Font.subheadline`（15pt） |
| `.banban-text-caption` | 13px / 400 | 1.5 | `Font.footnote`（13pt） |
| `.banban-text-label` | 13px / 500 | 1.4 | `Font.footnote.weight(.medium)` |

> **口径不一致披露**：`../handoff.md` §2.2 写「Caption 12px」，但 CSS 实际为 **13px**（`colors_and_type.css` L150）。**以 CSS 为准**（Swift 用 `.footnote` 13pt）；handoff §2.2 的 12px 视为笔误，待设计侧下次维护时更正。

> display / h1 的 `clamp()` 响应式字号在原生端没有直接对应物——语义字型已按 Dynamic Type 缩放，等效满足「随环境缩放」的意图；如需固定标题尺寸，用 `Font.system(size:)` 自定，但不推荐（损失无障碍缩放）。

## 6. 圆角 / 阴影 / safe-area

### 6.1 圆角

| CSS 变量 | 值 | Swift（`BanBanRadius`） |
| --- | --- | --- |
| `--banban-radius-small` | 4px | `small` |
| `--banban-radius-medium` | 8px | `medium` |
| `--banban-radius-large` | 12px | `large` |
| `--banban-radius-full` | 9999px | `full`（胶囊，建议用 `Capsule` 替代魔法数） |

### 6.2 阴影（双外观参数）

CSS 阴影为多层 box-shadow；Swift 用 `BanBanShadow.layers(level:dark:)` 返回层数组，`View.banbanShadow(_:)` 扩展按 `@Environment(\.colorScheme)` 自动切换（见 Swift 文件内示例）。CSS blur 值已按 iOS 惯例除以 2 折算为 `radius`。

| 级 | 浅色（层数：y / blur / 透明度） | 深色（默认） |
| --- | --- | --- |
| shadow-1 | 2 层：1/2/0.04 + 1/1/0.03 | 1 层：1/2/0.30 |
| shadow-2 | 2 层：8/24(-8)/0.08 + 4/8(-4)/0.05 | 2 层：8/24(-8)/0.50 + 4/8(-4)/0.40 |
| shadow-3 | 1 层：24/64(-12)/0.12 | 1 层：24/64(-12)/0.60 |

### 6.3 safe-area（不搬运为令牌）

CSS 的 `--banban-safe-*` 是 `env(safe-area-inset-*)` 的包装，用于浏览器原型模拟 iOS 安全区。**SwiftUI 原生处理安全区**（`GeometryReader.safeAreaInsets`、`.ignoresSafeArea()`、TabView / NavigationStack 自动留白），不需要也不要把这些令牌搬进 Swift。仅当用 UIKit 容器承载 SwiftUI 时才需要关心 `safeAreaInsets`。

## 7. 命名对照（`--banban-*` ↔ Swift）

| CSS 令牌 | Swift 消费入口 |
| --- | --- |
| `--banban-background` … `--banban-ring`（13 个语义别名） | `Color.banbanBackground` 等 `.banban<语义名>` 扩展（3.1 表右列） |
| `--banban-primary-50…950` | `BanBanBrandScale.p50…p950` |
| `--banban-neutral-0…950` | `BanBanNeutralScale.n0…n950` |
| `--banban-success/-warning/-error/-info` 及其 `-foreground` / `-subtle` | `BanBanColor.success` / `successForeground` / `successSubtle` … |
| `--banban-radius-*` | `BanBanRadius.small/.medium/.large/.full` |
| `--banban-shadow-1/2/3` | `BanBanShadow.layers(level:dark:)` + `View.banbanShadow(_:)` |
| `.banban-text-*` 排版类 | `BanBanFont.display/.h1/.h2/.bodyLarge/.body/.caption/.label` |
| `--banban-safe-*` | 不映射（SwiftUI 原生处理，见 6.3） |
