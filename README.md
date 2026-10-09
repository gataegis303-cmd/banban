# BanBan · 伴伴

iOS 交友 / 搭伴 APP 原型（SwiftUI / iOS 16+ / MVVM），面向 30+ 用户的严肃交友场景。

## 快速开始

```bash
# 克隆
git clone https://github.com/gataegis303-cmd/banban.git
cd banban

# 用 Xcode 打开
open ios/BanBan.xcodeproj

# 或命令行构建
cd ios
xcodebuild -project BanBan.xcodeproj -scheme BanBan -destination 'generic/platform=iOS Simulator' build
```

> 最低要求：macOS 13+ / Xcode 15+ / iOS 16.0+

## 命令

| 命令 | 说明 |
|------|------|
| `xcodebuild -project BanBan.xcodeproj -scheme BanBan -destination 'generic/platform=iOS Simulator' build` | 编译验证 |
| `xcodebuild -project BanBan.xcodeproj -scheme BanBan -destination 'platform=iOS Simulator,name=iPhone 15' build` | 指定模拟器构建 |

## 项目结构

```
BanBan/
├── ios/BanBan/              # Swift 工程
│   ├── App/                 # 入口（BanBanApp / AppRootView）
│   ├── Models/              # 数据模型（MyProfile / UserProfile / Conversation / ProfileDraft）
│   ├── Support/             # 全局状态（AppState）+ Mock 数据
│   ├── Theme/               # 设计令牌（BanBanTokens.swift — 颜色 / 字体 / 圆角 / 阴影）
│   ├── Views/               # SwiftUI 视图
│   │   ├── Components/      # 共享组件库（SharedComponents.swift）
│   │   ├── Auth/            # 认证流（引导 / 登录 / 实名认证 / 权限）
│   │   ├── Wizard/          # 资料向导（4 步注册 / 编辑双模式）
│   │   ├── Main/            # 主流程（首页卡片 / 筛选 / 详情 / 匹配成功）
│   │   ├── Messages/        # 消息流（会话列表 / 聊天）
│   │   └── Profile/         # 我的流（资料 / 设置 / 安全中心 / 隐私）
│   └── BanBan.entitlements  # App 权限配置
├── dev-handoff/             # 设计交接物料（令牌 / 组件清单 / 交互规格 / 校验）
├── pages/                   # 18 页 HTML 原型
├── handoff.md               # 设计综述（产品 / 设计 / 回顾视角）
└── docs/decisions/          # 架构决策记录（ADR）
```

## 架构概览

- **MVVM**：View 直接绑定 `@EnvironmentObject AppState`，无独立 ViewModel 层（原型阶段简化）
- **设计令牌系统**：`BanBanTokens.swift` 是 Swift 端唯一令牌来源，与 `colors_and_type.css` 逐一对应，禁止业务代码散布硬编码色值
- **Mock 数据**：`MockData.swift` 提供全量静态数据，无网络请求 / 无数据持久化
- **深色优先**：设计稿 18 页均为深色外观，Swift 动态色以深色值为默认分支

关键决策记录见 [docs/decisions/](docs/decisions/)。

## 开发约定

- 令牌文件头部标注「勿手改、跟随 CSS 更新」——色值变更须改 `colors_and_type.css` 再同步
- 设计资产（`BanBan.design` / `pages/*.html` / `colors_and_type.css`）为只读，开发期不改
- 提交信息中文，前缀：`feat:` / `fix:` / `chore:` / `refactor:` / `docs:`
- 构建验证以 `** BUILD SUCCEEDED **` 为准

## 版本

| 版本 | 说明 |
|------|------|
| v1.0.0 | 五轴代码审查全通过（1 Critical + 12 Required + Nit/Optional 打磨），正式版 |
| v0.1.0 | 全部视图开发完成，三端打包验证通过 |
