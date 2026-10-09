# ADR-001: SwiftUI + MVVM 架构

## Status
Accepted

## Date
2026-10-01

## Context

BanBan 是一款面向 30+ 用户的严肃交友 iOS APP。项目从设计阶段（Figma 画布 + 18 页 HTML 原型 + 交接文档）进入开发期，需要选择应用架构。

关键约束：
- iOS 16+ 最低版本（可用 NavigationStack、Swift Charts 等新 API）
- 团队规模小（1-2 人），需要快速迭代
- 原型阶段无后端，全部数据静态 mock
- 设计令牌已从 CSS 提取，需要 Swift 端落地

## Decision

使用 SwiftUI + MVVM 架构，但在原型阶段简化 ViewModel 层：

- View 直接通过 `@EnvironmentObject AppState` 获取和绑定数据
- `AppState` 作为唯一 `ObservableObject`，集中管理全局状态（阶段流转 / 资料 / 卡片 / 会话 / 筛选）
- 数据模型（`MyProfile` / `ProfileDraft` / `UserProfile` / `Conversation`）为纯值类型 `struct`
- 无独立 ViewModel 文件——View 内的计算属性和私有方法承担原 ViewModel 职责

## Alternatives Considered

### UIKit + MVC
- Pros: 成熟稳定，团队熟悉度高
- Cons: 代码量大（xib / 约束 / delegate 样板多），SwiftUI 的声明式 UI 更匹配设计稿的 HTML 原型
- Rejected: 开发效率不如 SwiftUI

### SwiftUI + TCA（The Composable Architecture）
- Pros: 状态管理更严格，可测试性强
- Cons: 学习成本高，依赖第三方库，原型阶段过度工程化
- Rejected: 引入复杂度与项目规模不匹配

### SwiftUI + 完整 MVVM（每 View 一个 ViewModel）
- Pros: 职责分离更清晰
- Cons: 原型阶段 View 数量多但逻辑简单，独立 ViewModel 层会产生大量样板代码
- Rejected: 原型阶段简化为 AppState 直接绑定，后续可按需引入

## Consequences

- AppState 承担了较多职责（阶段 / 资料 / 卡片 / 会话），后续功能增长时可能需要拆分
- View 与 AppState 耦合较紧，迁移到真实网络层时需要引入 Repository 层
- 纯值类型模型 + AppState `@Published` 属性的组合天然支持 SwiftUI 响应式更新
- 新 Agent 加入时只需理解 AppState 一个对象即可上手
