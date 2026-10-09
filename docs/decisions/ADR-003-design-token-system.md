# ADR-003: 设计令牌系统（CSS → Swift 单一来源）

## Status
Accepted

## Date
2026-10-01

## Context

BanBan 设计阶段产出了完整的令牌体系（颜色 / 排版 / 圆角 / 阴影），定义在 `colors_and_type.css` 中。iOS 端需要落地这套令牌，并保证后续设计变更时能精确同步。

## Decision

`BanBanTokens.swift` 作为 Swift 端唯一令牌来源，与 CSS 逐一对应：

- `BanBanColor`：静态色值 + `banbanDynamicColor(light:dark:)` 动态色辅助函数
- `BanBanFont`：映射到 SwiftUI 语义字型（`.title2` / `.body` / `.footnote` 等），自动跟随 Dynamic Type
- `BanBanRadius`：圆角常量（small=4 / medium=8 / large=12）
- `BanBanShadow`：阴影修饰符（1 级 / 2 级）
- `Color.banban*` 扩展：业务代码消费入口（如 `Color.banbanPrimary`、`BanBanFont.h2`）

令牌文件头部标注「勿手改、跟随 CSS 更新」。业务代码只消费令牌扩展，不散布硬编码值。

零引用令牌保留并标注 `// 预留：暂无消费方`，不删除（保留设计完整性，供后续功能消费）。

## Alternatives Considered

### Asset Catalog Color Set
- Pros: Xcode 原生支持，可视化编辑
- Cons: 每个颜色一个 `.colorset` 目录，维护繁琐；无法表达动态色逻辑；与 CSS 对照困难
- Rejected: 代码定义更易于与 CSS 比对和版本控制

### Tailwind-like 工具类
- Pros: 极简消费方式
- Cons: Swift 不适合链式工具类风格，且已有语义化扩展足够
- Rejected: 现有 `.banban*` 扩展模式更符合 Swift 惯例

## Consequences

- 令牌变更须先改 CSS 再同步 Swift，两处必须一致
- 动态色（`banbanDynamicColor`）在浅色/深色间自动切换，业务代码无需条件判断
- 状态色 `*-foreground` 在深色模式未覆盖，沿用浅色值（忠实设计稿）
- 新增令牌需在 CSS、BanBanColor 定义、Color 扩展三处同步
- 零引用令牌不删除，避免设计意图丢失
