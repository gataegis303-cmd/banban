# CLAUDE.md — BanBan 项目 Agent 约定

> 本文件供 AI Agent 读取，确保跨 session 一致性。

## 语言

- 对话、提交信息、代码注释均为中文。
- 代码标识符（变量名 / 函数名 / 类型名）用英文。

## 构建验证

```bash
cd ios
xcodebuild -project BanBan.xcodeproj -scheme BanBan -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "BUILD|error:"
```

以输出含 `** BUILD SUCCEEDED **` 为准。grep 管道退出码会误报，不要依赖退出码判断。

## 关键约定

### 设计令牌

- `BanBanTokens.swift` 是 Swift 端唯一令牌来源，与 `colors_and_type.css` 逐一对应。
- 禁止在业务代码中硬编码色值 / 字号 / 圆角 / 阴影值。
- 色值变更须先改 `colors_and_type.css`，再同步 Swift。
- 零引用令牌标注 `// 预留：暂无消费方`，不删除。

### 数据模型

- `ProfileDraft` 是向导编辑态草稿，`MyProfile` 是持久态。
- 新增资料字段需同步两处：`ProfileDraft.init(from: MyProfile)` 和 `MyProfile.merge(_:)`。
- `MyProfile.age` 以 `max(18, ...)` 钳制成车下限（18 = 成年）。
- `photoCount` 上限 6。

### AppState

- `cardIndex` 允许等于 `recommendations.count`（哨兵位，表示卡片已耗尽）。
- `advanceCard()` 用 `min` 兜底，不抛异常。
- `PreferredScheme` 仅 `.light` / `.dark`（规格为 Toggle 双态），无 `.system`。
- `preferredColorScheme.colorScheme` 返回非可选 `ColorScheme`。

### ComingSoon 模式

- 未实现功能统一用 `@StateObject private var comingSoon = ComingSoonModel()` + `.comingSoonAlert(comingSoon)`。
- 调用点 `comingSoon("功能名")`（`callAsFunction` 语法糖），不改调用点即可迁移。
- alert 文案集中管理在 `ComingSoonAlertModifier`，改一处全量生效。

### SettingRow

- `action: (() -> Void)? = nil`，nil 时渲染静态行（供 NavigationLink label 使用，避免内层 Button 吞点击）。

### Skip 防回归清单

以下重构已评估并决定不做（收益低 / 改动面大）：
- VerifyIDView / WizardStep4 body 拆分
- TransportStepper 与 StepperRow 合并
- Step1 Binding 三件套简化
- MyProfileView 齿轮复用 CircleIconButton（它是 NavigationLink 非 Button）

## 提交规范

- 中文提交信息，前缀：`feat:` / `fix:` / `chore:` / `refactor:` / `docs:`
- trunk-based，直接提交到 main
- 文件重叠多的改动用单个提交
- heredoc 传递 body

## 设计资产（只读）

以下文件是设计阶段定稿，开发期不改：
- `BanBan.design` — Figma 画布
- `pages/*.html` — 18 页 HTML 原型
- `colors_and_type.css` — 令牌权威来源
- `generation-tree.json` — 生成树
- `runtime-orchestration-summary.json` — 编排摘要

## 已知限制

- 无测试（原型阶段，全部逻辑静态可验）
- 无网络层 / 无数据持久化（MockData 静态数据）
- 无 CI/CD（手动构建验证）
- `.autocorrectionDisabled(!autocorrect)` 默认关闭，未来长文本字段（如简介）应传 `autocorrect: true`
