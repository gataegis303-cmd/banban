# ADR-004: PreferredScheme 双态 Toggle（非三态）

## Status
Accepted

## Date
2026-10-09

## Context

BanBan 设计稿 18 页均为深色外观（`<html class="dark">`）。交互规格（`03-interaction-specs.md`）将深色模式定义为设置页的 Toggle 双态切换（开/关），而非三选一（跟随系统/浅色/深色）。

初始实现误设了三态枚举（`.system` / `.light` / `.dark` + `CaseIterable` + `Identifiable` + `title`），但 `.system` case 从未被消费。

## Decision

将 `PreferredScheme` 精简为双态：

```swift
enum PreferredScheme: String {
    case light
    case dark
    var var colorScheme: ColorScheme { ... }  // 非可选
}
```

- 删除 `.system` case 及其 `title` 属性
- 删除 `CaseIterable` / `Identifiable` 协议（无 ForEach / allCases 消费方）
- `colorScheme` 从 `ColorScheme?` 改为 `ColorScheme`（非可选）
- `BanBanApp.swift` 的 `.preferredColorScheme()` 自动桥接非可选值
- SettingsView 用 `ToggleRow(isOn: $darkMode)` + `onChange` 同步

## Alternatives Considered

### 保留三态 + Picker 选择器
- Pros: 支持跟随系统
- Cons: 设计规格明确为 Toggle 双态；`.system` 从未使用；增加未实现的选项误导用户
- Rejected: 不符合交互规格

### 删除枚举，直接用 Bool
- Pros: 最简
- Cons: 语义不清晰（`true` 是深色还是浅色？），后续扩展不便
- Rejected: 枚举语义更清晰

## Consequences

- 如后续需要「跟随系统」功能，新增 `.system` case 并恢复 `colorScheme` 为可选即可
- `SettingsView.onAppear` 中 `darkMode = appState.preferredColorScheme == .dark` 是唯一同步点
- 双态语义与设计稿 Toggle 完全一致
