# ADR-005: ComingSoon 统一反馈模式

## Status
Accepted

## Date
2026-10-09

## Context

BanBan 原型中大量功能按钮没有真实实现（修改手机号、清除缓存、消息通知、举报记录、黑名单等）。初始实现中每个 View 各自维护 `@State showsComingSoon` + `@State comingSoonTitle` + `.alert(...)` + `comingSoon(_:)` 方法，5 个 View 逐字复制，维护成本高（改 alert 文案要改 5 处）。

## Decision

封装为 `ComingSoonModel` + `ComingSoonAlertModifier`：

```swift
@MainActor
final class ComingSoonModel: ObservableObject {
    @Published var shows = false
    @Published var title: String?
    func callAsFunction(_ title: String) { ... }  // 语法糖，调用点不变
}

extension View {
    func comingSoonAlert(_ model: ComingSoonModel) -> some View { ... }
}
```

每个 View 只需：
- `@StateObject private var comingSoon = ComingSoonModel()`
- `.comingSoonAlert(comingSoon)`（一行修饰符）
- 调用点 `comingSoon("功能名")` 不变（`callAsFunction` 语法糖）

## Alternatives Considered

### ViewModifier + EnvironmentKey（闭包注入）
- Pros: 调用方零样板
- Cons: SwiftUI environment 值由 modifier 设置后只对子视图可见，View 自身的 `@Environment` 属性读不到父级 modifier 注入的值，导致触发闭包为默认 no-op
- Rejected: 作用域限制导致同一 View 无法既挂载又触发

### 每 View 各自维护（保留现状）
- Pros: 无需抽象
- Cons: 5 处复制，alert 文案 / 按钮文案变更需改 5 处
- Rejected: 维护成本高

### 全局 AppState 管理
- Pros: 集中管理
- Cons: AppState 职责膨胀；alert 是 View 层关注点，不应上升至全局状态
- Rejected: 职责边界不清

## Consequences

- alert 文案 / 按钮文案变更只需改 `ComingSoonAlertModifier` 一处
- 新增 ComingSoon 功能只需 `@StateObject` + `.comingSoonAlert()` + 调用 `comingSoon("xxx")`
- `callAsFunction` 让调用点保持 `comingSoon("xxx")` 形式，迁移时无需改调用点
- 迁移到真实实现时：移除 `@StateObject` 和 `.comingSoonAlert()`，将调用点替换为真实逻辑
