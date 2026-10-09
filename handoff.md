# 伴伴 BanBan — iOS 设计交付文档

## 1. 项目概述

**伴伴 BanBan** 是一款面向「不婚者」的异性搭伴生活中介平台 iOS App 设计原型。本阶段交付物为可点击的高保真交互原型（HTML + CSS），覆盖从启动、认证、资料创建、匹配、消息到安全隐私设置的完整 P0 用户旅程。原生 Swift/SwiftUI 开发与后端服务方案待后续阶段决策。

- **项目路径**：`BanBan/`
- **设计画布**：`BanBan.design`
- **设计 Token**：`colors_and_type.css`
- **页面文件**：`pages/*.html`（共 18 页）

## 2. 设计语言与 Token

> **外观模式：深色模式（默认）**。所有页面均以 `class="dark"` 渲染，以下为当前生效的深色 Token。浅色版 Token 保留在 `colors_and_type.css` 的 `:root` 语义别名区（`.dark` 块覆盖深色值），可随时切换。

### 2.1 品牌色彩

主色为 **Apple 系统蓝（iOS System Blue）**，深色模式为默认外观：纯黑背景 + iOS 系统灰阶 + 系统语义色，整体贴合苹果原生设计语言。

| Token | 色值（Dark） | 用途 |
| --- | --- | --- |
| `--banban-background` | `#000000` | 页面背景（纯黑，iOS 系统深色底） |
| `--banban-card` | `#1C1C1E` | 卡片、浮层表面 |
| `--banban-popover` | `#3A3A3C` | 弹出层 |
| `--banban-muted` | `#1C1C1E` | 次级底色、禁用背景 |
| `--banban-border` / `--banban-input` | `#3A3A3C` | 分隔线、边框、输入描边 |
| `--banban-primary-500` | `#007AFF`（暗色下以 `primary-400` `#2E8DFF` 强化） | 主按钮、激活态、强调色 |
| `--banban-foreground` | `#F5F5F7` | 主文字 |
| `--banban-muted-foreground` | `#8E8E93` | 次要文字（iOS systemGray） |
| `--banban-error` / `--banban-success` / `--banban-warning` / `--banban-info` | `#FF3B30` / `#34C759` / `#FF9500` / `#007AFF` | 状态色（含 subtle 暗底） |

浅色基准（备用）：`primary-500 #007AFF`、背景 `#FFFFFF`、主文字 `#1D1D1F`、次要文字 `#8E8E93`。

### 2.2 字体与排版

- **字体栈**：`-apple-system, BlinkMacSystemFont, "SF Pro", "PingFang SC", "Noto Sans SC", "Microsoft YaHei", system-ui, sans-serif`
- **字号层级**：Caption 12px / Body 15–17px / Title 20–22px / Display 32–48px
- **行高**：正文 1.5–1.6，标题 1.2–1.3

### 2.3 圆角与阴影

- 圆角：`4px / 8px / 12px / 9999px`
- 静态表面阴影透明度 ≤ 0.05；浮层可使用更强的 `shadow-2` / `shadow-3`

## 3. 页面清单（18 页）

| 页面 ID | 文件名 | 标题 | 说明 |
| --- | --- | --- | --- |
| `page-onboarding` | `onboarding.html` | 启动页 | 品牌介绍、注册/登录入口 |
| `page-login` | `login.html` | 手机号登录 | 手机号输入、验证码、用户协议 |
| `page-verify-id` | `verify-id.html` | 实名认证 | 身份证 + 人脸识别认证 |
| `page-permissions` | `permissions.html` | 权限请求 | 位置、通知、相册授权 |
| `page-profile-wizard-1` | `profile-wizard-1.html` | 资料创建 · 基础 | 昵称、性别、生日、城市、职业、婚姻状态、子女情况 |
| `page-profile-wizard-2` | `profile-wizard-2.html` | 资料创建 · 生活 | 吸烟、饮酒、作息、宠物 |
| `page-profile-wizard-3` | `profile-wizard-3.html` | 资料创建 · 意向 | 搭伴方向、可接受伴侣状态、搭伴对象（含选项说明浮窗）、居住模式、试用期财务管理、正式关系后财务管理、生育意愿、社交边界、与父母关系、我不能接受（可多选）、意向城市 |
| `page-profile-wizard-4` | `profile-wizard-4.html` | 资料创建 · 照片 | 我可提供资源板（出行工具 / 居住情况 / 居住条件 / 资源 / 其他五组，可多选 + 统一未使用房间数步进器 + 打车月额度 + 标签录入）、头像与生活照上传 |
| `page-my-profile` | `my-profile.html` | 我的资料 | 个人资料展示与编辑入口 |
| `page-home` | `home.html` | 推荐首页 | 每日推荐卡片、筛选、喜欢/跳过 |
| `page-filter` | `filter.html` | 筛选面板 | 城市、年龄、搭伴方向、可接受伴侣状态、搭伴对象、居住模式、与父母关系、试用期财务管理、正式关系后财务管理、生育意愿、宠物筛选、不能接受 |
| `page-profile-detail` | `profile-detail.html` | 他人资料 | 对方完整资料、喜欢/跳过 |
| `page-match-success` | `match-success.html` | 匹配成功 | 双向喜欢后的成功页 |
| `page-messages` | `messages.html` | 消息列表 | 聊天列表、 likes 列表 |
| `page-chat` | `chat.html` | 聊天界面 | 单聊、举报、更多 |
| `page-safety` | `safety.html` | 安全中心 | 举报记录、黑名单、紧急联系人 |
| `page-privacy` | `privacy.html` | 隐私设置 | 可见性、在线状态、手机号搜索 |
| `page-settings` | `settings.html` | 设置 | 账号、通知、通用、关于、退出登录 |

## 4. 核心交互流

### 4.1 注册与认证流程

```
onboarding → login → verify-id → permissions
                          ↓ (关闭)
                      login
```

### 4.2 资料创建流程

```
permissions → profile-wizard-1 → profile-wizard-2 → profile-wizard-3 → profile-wizard-4 → my-profile
```

每步均有返回上一步的能力。

### 4.3 核心匹配流程

```
home → profile-detail → match-success → chat
  ↓        ↓                ↓
filter   home(跳过)      home(继续浏览)
```

- 首页卡片点击可进入他人资料详情。
- 详情页和首页均支持「喜欢」与「跳过」。
- 双向喜欢后进入匹配成功页，可选择立即聊天或返回首页。

### 4.4 消息流程

```
messages → chat → messages
  ↓
home / my-profile (底部导航)
```

### 4.5 我的页面导航

```
my-profile → settings → privacy
     ↓           ↓
profile-wizard-1  safety
```

## 5. 底部导航

四栏底部标签栏仅出现在主应用页面：

| 图标 | 标签 | 激活页 |
| --- | --- | --- |
| Home | 首页 | `page-home` |
| MessageCircle | 消息 | `page-messages` |
| Users | 广场 | 暂未实现，点击回到首页 |
| User | 我的 | `page-my-profile` |

认证流程（onboarding / login / verify-id / permissions / profile-wizard-*）不显示底部导航。

## 6. 资产策略

- **无生成照片素材**：所有头像、场景图均使用 CSS 抽象占位图或 Lucide 图标，避免真人肖像版权风险。
- **图标**：使用 [Lucide Icons](https://lucide.dev/)，通过 `data-lucide` 属性在页面加载时渲染。
- **图形**：启动插画、空状态、成功动画均使用纯 CSS/SVG 绘制。
- **字体**：依赖系统字体栈，无需额外字体文件。

## 7. iOS 实现建议

### 7.1 技术栈

- **UI 框架**：SwiftUI（推荐）或 UIKit + SwiftUI 混合。
- **最低版本**：iOS 16+，以使用 SwiftUI NavigationStack 与原生组件。
- **架构**：MVVM 或 TCA（The Composable Architecture）。

### 7.2 关键组件映射

| 设计元素 | SwiftUI 组件 |
| --- | --- |
| 底部导航 | `TabView` |
| 推荐卡片 | `ZStack` + `Card` 自定义视图 |
| 筛选面板 | `.sheet` 或全屏 `NavigationStack` push |
| 资料创建步骤 | `NavigationStack` + 自定义 `Stepper` |
| 聊天 | `ScrollView` + `LazyVStack` |
| 开关 | `Toggle`（iOS 风格） |

### 7.3 安全与隐私

- 实名认证 + 人脸识别为使用核心功能的**强制前置条件**。
- 真实姓名、手机号、精确地址默认对其他用户隐藏。
- 聊天界面提供一键举报入口。
- 紧急联系人、黑名单、举报记录均已在安全中心页面预留入口。

### 7.4 匹配机制

- 首页与详情页展示推荐用户。
- 用户点击「喜欢」后，系统记录偏好；原型中直接跳转至匹配成功页，模拟双向匹配。
- 实际开发中应实现：后端判断双向喜欢 → 推送匹配成功 → 解锁聊天。

## 8. 文件结构

```
BanBan/
├── BanBan.design                     # 设计画布（含页面节点与交互定义）
├── colors_and_type.css               # 设计 Token：色彩、字体、圆角、阴影
├── runtime-orchestration-summary.json # 运行编排摘要
├── generation-tree.json              # 生成树状态
├── handoff.md                        # 本交付文档
├── .preflight/
│   └── preflight.html                # CSS 预检文件
└── pages/
    ├── onboarding.html
    ├── login.html
    ├── verify-id.html
    ├── permissions.html
    ├── profile-wizard-1.html
    ├── profile-wizard-2.html
    ├── profile-wizard-3.html
    ├── profile-wizard-4.html
    ├── my-profile.html
    ├── home.html
    ├── filter.html
    ├── profile-detail.html
    ├── match-success.html
    ├── messages.html
    ├── chat.html
    ├── safety.html
    ├── privacy.html
    └── settings.html
```

## 9. 原型操作说明

1. 在 Trae 设计画布中打开 `BanBan.design`。
2. 点击任意页面即可查看高保真设计。
3. 带有 `data-dom-id` 的按钮、卡片、列表项均已注册点击跳转，可在预览模式下点击体验完整流程。
4. 底部导航、返回按钮、核心 CTA 均已连线。

## 10. 已知限制与下阶段建议

- **广场页**：当前设计中「广场」标签点击后回到首页，作为占位。后续可扩展为话题、动态、活动社区。
- **真实照片**：当前使用抽象占位图，正式上线前需接入用户上传与内容审核。
- **后端服务**：认证、匹配、消息、举报、隐私控制均需后端支持，技术选型待后续确定。
- **动效**：当前原型为静态 + 简单 active 状态，iOS 开发阶段建议加入转场动画、卡片滑动、骨架屏等细节。
- **无障碍**：已预留 `aria-label` 与语义化角色，开发阶段需补充 VoiceOver 朗读与动态焦点管理。

## 11. 验证状态

- 已运行自定义 Python 验证脚本，确认：
  - 18 个 HTML 页面文件完整存在
  - 3 个 JSON 元数据文件可解析
  - 所有交互目标指向有效的页面 ID
  - 所有交互 `data-dom-id` 在对应 HTML 中真实存在
  - 每页均包含 viewport、title 等必要 head 元素

**验证结果：通过。**

### 11.1 深色主题改造验证（2026-10-01）

主题切换采用「仅换 Token、不动结构」的就地改造，验证脚本二次确认：

- 全部 18 页 `<html>` 已切换为 `class="dark"`
- 每页 `<style id="theme-vars">` 为干净内联的深色 Token（已清除历史行号前缀污染）
- 深色背景 Token（`#0E100F`）与状态色 subtle 暗底均已注入
- DiceBear 头像占位的背景参数已同步为暗色（`232823`），无残留浅色参数
- 页面结构、布局与全部 63 个交互连线保持不变

### 11.2 与父母关系字段同步验证（2026-10-02）

筛选面板新增「与父母关系」筛选组（与父母同住 / 就近居住 / 异地 / 其他），并同步至资料闭环，全部就地编辑：

- `filter.html`：居住模式与财务分摊之间新增筛选组，复用 `tag-checkbox` 胶囊样式，多选交互（`filter-parent-*` 共 4 个 dom-id）
- `profile-wizard-3.html`：社交边界与意向城市之间新增单选分段控件（2×2 网格，`parent-*` 4 个 dom-id），JS 分组数组已加入 `'parent'`
- `my-profile.html`：搭伴意向卡片「期望城市」与「开始时间」之间新增「与父母关系：就近居住」行
- `profile-detail.html`：搭伴意向标签组新增「与父母异地」胶囊
- 元数据与校验：`runtime-orchestration-summary.json` 的 `domIdsRequired` 追加 8 个新 dom-id，校验脚本新增检查 8（parent-relation 标记），完整校验通过（exit 0）

### 11.3 财务分配倾向字段同步验证（2026-10-03）

筛选面板新增「财务分配倾向」筛选组（AA / 共同财产，label 下带「关系成立后」说明行，与「财务分摊」区分），并同步至资料闭环，全部就地编辑：

- `filter.html`：财务分摊与生育意愿之间新增筛选组，复用 `tag-checkbox` 胶囊样式，多选交互（`filter-wealth-aa` / `filter-wealth-joint` 共 2 个 dom-id）
- `profile-wizard-3.html`：财务分摊与是否生育之间新增单选分段控件（2 键网格，`wealth-aa` / `wealth-joint` 2 个 dom-id），JS 分组数组已加入 `'wealth'`
- `my-profile.html`：搭伴意向卡片「与父母关系」与「开始时间」之间新增「财务分配倾向：AA」行
- `profile-detail.html`：搭伴意向标签组「AA 分摊」与「不生育」之间新增「共同财产」胶囊（6 → 7 枚）
- 元数据与校验：`runtime-orchestration-summary.json` 的 `domIdsRequired` 追加 4 个新 dom-id，校验脚本 docstring 升至 v4 并新增检查 9（wealth-preference 标记），完整校验通过（exit 0）

### 11.4 伴侣状态与搭伴对象字段同步验证（2026-10-03）

用户原始需求为 6 个混合选项（未婚无伴侣、已婚分居、离异找同性、离异找异性、女同找男伴、男同找女伴），用于定位当前伴侣状态、方便快速匹配。设计评估发现其混合了「伴侣状态」（婚姻/关系现状）与「搭伴对象」（寻找方向）两个独立维度，单组互斥选项无法表达组合且语义冲突、无法按维度独立筛选，故重构为两个正交单选字段（组合自由度 6 → 12），原 6 选项全部无损映射，全部就地编辑：

| 原选项 | 新字段组合 |
| --- | --- |
| 未婚无伴侣 | 伴侣状态 = 未婚无伴侣（搭伴对象自选） |
| 已婚分居 | 伴侣状态 = 已婚分居（搭伴对象自选） |
| 离异找同性 | 伴侣状态 = 离异 + 搭伴对象 = 同性搭伴 |
| 离异找异性 | 伴侣状态 = 离异 + 搭伴对象 = 异性搭伴 |
| 女同找男伴 | 搭伴对象 = 形式搭伴（无浪漫关系的搭伴约定） |
| 男同找女伴 | 搭伴对象 = 形式搭伴（无浪漫关系的搭伴约定） |

- `filter.html`：年龄与居住模式之间新增「伴侣状态」筛选组（未婚无伴侣 / 已婚分居 / 离异，`filter-status-*` 共 3 个 dom-id，label 同「居住模式」mb-3 变体）与「搭伴对象」筛选组（异性搭伴 / 同性搭伴 / 形式搭伴 / 不限，`filter-seek-*` 共 4 个 dom-id，label 下带「形式搭伴：无浪漫关系的搭伴约定」说明行，同「财务分配倾向」caption 变体）
- `profile-wizard-3.html`：表单最前（居住模式之前）新增「伴侣状态」（3 键网格，`status-unmarried` / `status-separated` / `status-divorced`）与「搭伴对象」（2 键网格含说明行，`seek-opposite` / `seek-same` / `seek-form` / `seek-any`）两个单选分段控件，JS 分组数组已加入 `'status'`、`'seek'`
- `my-profile.html`：搭伴意向卡片「搭伴类型」之后新增「伴侣状态：未婚无伴侣」「搭伴对象：异性搭伴」两行（既有「婚姻状况：未婚」行保留——婚姻登记状况与新「伴侣状态」语义不同，前者为登记状态、后者为匹配导向的当前伴侣状态）
- `profile-detail.html`：搭伴意向标签组「分房居住」之前新增「离异」「同性搭伴」胶囊（7 → 9 枚，对应示例人物安然：离异 + 同性搭伴）
- 元数据与校验：`runtime-orchestration-summary.json` 的 `domIdsRequired` 追加 14 个新 dom-id（wizard-3 22 → 29，filter 27 → 34），校验脚本 docstring 升至 v5 并新增检查 10（status-seek 标记），完整校验第 1 次运行通过（exit 0）

### 11.5 搭伴对象选项说明浮窗（2026-10-03）

`profile-wizard-3.html` 的「搭伴对象」标签旁新增（!）说明入口，点击弹出浮窗，对 4 个选项（异性搭伴 / 同性搭伴 / 形式搭伴 / 不限）逐一给出对应说明，帮助用户理解各选项的边界与适用场景。全部就地编辑，仅改动该页：

- 触发按钮：标签行内 `alert-circle` 图标按钮（16px 图标、24px 点击区，`data-dom-id="btn-seek-help"`，带 `aria-label="搭伴对象选项说明"` 与 `aria-haspopup="dialog"`），位于「搭伴对象」文字右侧
- 浮窗结构：全屏遮罩（`fixed inset-0 z-50 bg-black/60 backdrop-blur-sm`）+ 居中面板（`max-w-md rounded-xl bg-popover text-popover-foreground shadow-[var(--banban-shadow-3)]`，复用页面既有 popover token 与暗色投影 token），标题「搭伴对象说明」+ 副标题，下方 4 张说明卡片（`bg-background` 描边卡，标题 + 一行说明）：
  - 异性搭伴：与异性结伴参加活动或互相陪伴，不含恋爱目的，双方需提前明确边界。
  - 同性搭伴：与同性结伴出行或参加活动，兴趣与作息更容易一致，相处更放松。
  - 形式搭伴：无浪漫关系的搭伴约定，仅就具体事项（如旅行、健身、拼车）相互协作。（复用既有 caption 语义并扩展示例）
  - 不限：不限定搭伴对象的性别与关系形式，更看重兴趣匹配与相处舒适度。
- 关闭方式：底部「知道了」主按钮、点击遮罩空白区、按 Esc 键，三种方式等价
- 实现注意：浮窗容器 dom-id 定为 `help-overlay` / `help-panel`（而非 `seek-help-*`），避免与分段控件 JS 的 `[data-dom-id^="seek-"]` 前缀选择器冲突；开关逻辑追加在既有 IIFE 内（`openSeekHelp` / `closeSeekHelp`），分段控件分组数组未改动
- 元数据与校验：`runtime-orchestration-summary.json` 的 wizard-3 `domIdsRequired` 追加 4 个新 dom-id（29 → 33），校验脚本 docstring 升至 v6 并新增检查 11（seek-help popover 标记），完整校验第 1 次运行通过（exit 0）

### 11.6 我不能接受多选字段（负面词 + 中性词）（2026-10-03）

新增「我不能接受」多选字段作为匹配辅助：用户从 15 个婚恋市场常见词中多选不能接受的特质，四处页面同步（全部就地编辑，画布零手动改动）：

- 选项清单（15 项）：负面词 9 个——妈宝、邋遢、花心、冷暴力、撒谎成性、控制欲强、嗜酒嗜赌、啃老、斤斤计较（品行/行为红旗）；中性词 6 个——养宠、吸烟、饮酒、与父母同住、异地恋、工作狂（生活方式属性，中性但常为排除项）
- `profile-wizard-3.html`：「与父母关系」与「意向城市」之间新增「我不能接受」字段（label +「可多选 · 匹配时帮你避开这些特质」caption），分「负面词」「中性词」两个子组，各为 flex-wrap 圆角胶囊（`rounded-full border border-border bg-card` 未选中态）；多选为独立 toggle 处理器（选择器 `[data-dom-id^="no-"]`），选中时显式交换 `bg-card/text-muted-foreground/hover:*` ↔ `bg-primary/text-primary-foreground` 并切换 `aria-pressed`，不依赖 CSS 声明顺序；处理器不入分段控件 groups 数组（检查 8/10 的 needle 不受影响），说明浮窗逻辑无改动
- `filter.html`：「宠物」组之后新增「不能接受」筛选组，15 枚胶囊单组平铺（与 wizard-3 分组呈现差异化），复用既有 `tag-checkbox` 三层结构与纯 CSS `:checked` 选中态，零 JS；label 下沿用「财务分配倾向」caption 变体：「不能接受（排除）：匹配时排除含这些特质的用户」
- `my-profile.html`：搭伴意向卡片「搭伴对象」行之后新增「我不能接受：妈宝、斤斤计较、吸烟」展示行（结构与既有行一致，不带 dom-id）
- `profile-detail.html`：搭伴意向胶囊组之后以分隔线 + 中性文本呈现「不能接受：冷暴力、花心」（示例人物安然：离异 + 同性搭伴 + 自述不接受冷战，人设自洽）；刻意不用 `bg-primary/10` 正向胶囊，避免排除语义与正向强调色混淆
- 命名与无冲突验证：wizard-3 用 `no-*` 前缀（15 个），filter 用 `filter-no-*` 前缀（15 个）；既有 dom-id 无 `no-`/`filter-no-` 前缀（`child-no` 以 `child-` 开头，不被 `[data-dom-id^="no-"]` 误匹配）；`filter-pet-*` 与 `filter-no-pet` 互不冲突
- 维度区别：「与父母同住」在 wizard-3 中有两个语义入口——「与父母关系」组的 `parent-together` 描述用户自述现状，本字段的 `no-liveparent` 表达匹配排除项，二者独立不联动
- 元数据与校验：`runtime-orchestration-summary.json` 的 `domIdsRequired` 追加 30 个新 dom-id（wizard-3 33 → 48，filter 34 → 49；my-profile / profile-detail 无交互不注册），校验脚本 docstring 升至 v7 并新增检查 12（cannot-accept 标记 + 15/15 dom-id 计数断言），完整校验第 1 次运行通过（exit 0）

### 11.7 搭伴对象选项精简（2026-10-08）

「搭伴对象」选项由「异性搭伴 / 同性搭伴 / 形式搭伴 / 不限」精简为「异性 / 同性 / 不限」（用户指定；「形式搭伴」整体移除），四处页面同步（全部就地编辑，画布零手动改动）：

- `profile-wizard-3.html`：字段说明行「形式搭伴：无浪漫关系的搭伴约定」移除（解释对象已删除）；分段控件 `grid-cols-2` → `grid-cols-3` 单行三选项，按钮文案改为 异性 / 同性 / 不限，dom-id 沿用 `seek-opposite` / `seek-same` / `seek-any`，`seek-form` 按钮删除（分段 JS 为前缀驱动的 groups 数组，无需改动）；（!）说明浮窗由 4 卡减为 3 卡（异性 / 同性 / 不限，各卡说明文案不变），浮窗结构、开关逻辑与 4 个浮窗 dom-id（`btn-seek-help` / `help-overlay` / `help-panel` / `btn-seek-help-close`）不变
- `filter.html`：「搭伴对象」筛选组同步精简为 3 枚复选（异性 / 同性 / 不限），`filter-seek-form` 删除，说明行移除，label 补 `mb-3`（对齐「伴侣状态」组间距变体）
- `my-profile.html`：搭伴对象展示行值「异性搭伴」→「异性」；`profile-detail.html`：安然搭伴意向胶囊「同性搭伴」→「同性」
- dom-id 变化：wizard-3 `domIdsRequired` 48 → 47（移除 `seek-form`），filter 49 → 48（移除 `filter-seek-form`）；已核对 `BanBan.design` 无 `seek-form` / `filter-seek-form` / 「形式搭伴」交互引用
- 校验脚本 v8：检查 10 needle「同性搭伴」→「同性」，检查 11 移除「形式搭伴」卡片说明 needle（其余 popover needles 与检查 12 不变）；完整校验通过（exit 0）

### 11.8 居住模式选项改名（2026-10-08）

「居住模式」选项由「同居 / 分房 / 视情况而定」改名为「同居同房 / 同居分房 / 同城分居」（用户指定；三态语义补全：同住同室 / 同住分室 / 同城分开居住），三处页面同步（全部就地编辑，画布零手动改动）：

- `profile-wizard-3.html`：分段控件三键文案改名（同居 → 同居同房、分房 → 同居分房、视情况而定 → 同城分居），dom-id 沿用 `live-together` / `live-separate` / `live-flexible` 不变，`grid-cols-3` 布局与分段 JS 不动
- `filter.html`：「居住模式」筛选组三枚复选同步改名（同居 / 分房 / 灵活 → 同居同房 / 同居分房 / 同城分居），dom-id 沿用 `filter-live-together` / `filter-live-separate` / `filter-live-flexible` 不变
- `home.html` / `profile-detail.html`：安然示例芯片「分房居住」→「同居分房」（对齐新词表）；`my-profile.html` 的「居住情况：独居」为自述现状字段，与本匹配字段无关，不改
- dom-id 变化：无（仅文案改名，wizard-3 47 / filter 48 计数不变）；`BanBan.design` 交互仅引用 dom-id、无文案耦合，已核对无破坏
- 校验脚本 v9：新增检查 13（living-mode 三选项在 wizard-3 / filter 及首页、资料详情芯片处的 8 个 needle）；完整校验通过（exit 0）

### 11.9 财务分摊字段改名与选项精简（2026-10-08）

「财务分摊」字段改名为「试用期财务管理」，选项由「AA / 按收入比例 / 各管各 / 再商量」精简为「AA / 按收入比例 / 一事一议」（用户指定；「各管各」移除，「再商量」语义并入「一事一议」），全部就地编辑，画布零手动改动：

- `profile-wizard-3.html`：字段 label 改名；分段控件 `grid-cols-2` → `grid-cols-3` 三选项（AA / 按收入比例 / 一事一议），dom-id 沿用 `finance-aa` / `finance-ratio` / `finance-discuss`，`finance-separate` 按钮删除（分段 JS 为前缀驱动 groups 数组，无需改动）
- `filter.html`：筛选组 label 与注释同步改名，4 枚复选减为 3 枚（AA / 按收入比例 / 一事一议），`filter-finance-separate` 删除，「比例」→「按收入比例」、「商量」→「一事一议」文案对齐
- `home.html` / `profile-detail.html`：安然示例芯片「AA 分摊」→「AA」（对齐选项值，「分摊」属旧字段名用词）；`my-profile.html` 无财务分摊行，无需改动；`onboarding.html` L293「同居方式、财务分摊…」为宣传性描述文案（非字段枚举，同「同居方式 ≠ 居住模式」先例），保持不动
- dom-id 变化：wizard-3 `domIdsRequired` 47 → 46（移除 `finance-separate`），filter 48 → 47（移除 `filter-finance-separate`）；已核对 `BanBan.design` 无 `finance-separate` / `filter-finance-separate` 交互引用
- 校验脚本 v10：新增检查 14（试用期财务管理 / 按收入比例 / 一事一议 在 wizard-3 / filter 及首页、资料详情芯片处的 7 个 needle）；完整校验通过（exit 0）

### 11.10 财务分配倾向字段改名与选项扩充（2026-10-08）

「财务分配倾向（关系成立后）」字段改名为「正式关系后财务管理」，选项由「AA / 共同财产」扩充为「AA / 按收入比例 / 一事一议 / 共同财富」（用户指定；与试用期财务管理选项对齐并新增「共同财富」终态），全部就地编辑，画布零手动改动：

- `profile-wizard-3.html`：字段 label 改名，「关系成立后」说明行删除（时机语义已并入新字段名）；分段控件 2 键 → 4 键（2×2 网格，`grid-cols-2` 不变），沿用 `wealth-aa` / `wealth-joint`（文案改「共同财富」），新增 `wealth-ratio` / `wealth-discuss`（JS 分组数组 `'wealth'` 前缀驱动，新键自动纳入单选交互）
- `filter.html`：筛选组 label 改名，caption「关系成立后」删除（label 改用 `mb-3` 间距变体），2 枚复选扩为 4 枚（AA / 按收入比例 / 一事一议 / 共同财富），新增 `filter-wealth-ratio` / `filter-wealth-discuss`
- `my-profile.html`：展示行「财务分配倾向：AA」→「正式关系后财务管理：AA」（示例值 AA 仍为合法选项，保留）
- `profile-detail.html`：安然示例胶囊「共同财产」→「共同财富」
- dom-id 变化：wizard-3 `domIdsRequired` 46 → 48（新增 `wealth-ratio` / `wealth-discuss`），filter 47 → 49（新增 `filter-wealth-ratio` / `filter-wealth-discuss`），无删除；已核对 JSON 插入位置与页面 dom 顺序一致
- 校验脚本 v11：检查 9 needle 同步（my-profile「财务分配倾向」→「正式关系后财务管理」、profile-detail「共同财产」→「共同财富」），新增检查 15（正式关系后财务管理 / 共同财富 在 wizard-3 / filter / my-profile / profile-detail 的 6 个 needle）；完整校验通过（exit 0）

### 11.11 生育意愿选项扩充（2026-10-08）

「是否生育 / 生育意愿」选项由「是 / 否 / 不确定」（wizard-3）与「要 / 不要 / 不确定」（filter）统一扩充为「是 / 否 / 领养 / 不确定」（用户指定；筛选页旧措辞「要 / 不要」一并对齐），全部就地编辑，画布零手动改动：

- `profile-wizard-3.html`：分段控件 3 键 → 4 键（`grid-cols-3` → `grid-cols-4` 单行，「是 / 否 / 领养 / 不确定」），沿用 `child-yes` / `child-no` / `child-uncertain`，新增 `child-adopt`（JS 分组数组 `'child'` 前缀驱动，新键自动纳入单选交互；`child-` 前缀与「我不能接受」的 `[data-dom-id^="no-"]` 选择器无交集，§11.6 结论不受影响）
- `filter.html`：生育意愿筛选组 3 枚复选 → 4 枚（是 / 否 / 领养 / 不确定），沿用 `filter-child-yes` / `filter-child-no` / `filter-child-uncertain`，新增 `filter-child-adopt`
- `home.html` / `profile-detail.html`：安然示例芯片「不生育」→「否」（对齐选项值）；`my-profile.html` 无生育意愿行，无需改动
- dom-id 变化：wizard-3 `domIdsRequired` 48 → 49（新增 `child-adopt`），filter 49 → 50（新增 `filter-child-adopt`），插入位置与页面 dom 顺序一致，无删除
- 校验脚本 v12：新增检查 16（领养 / child-adopt / filter-child-adopt 在 wizard-3 / filter 及首页、资料详情芯片「>否</span>」处的 6 个 needle）；完整校验通过（exit 0）

### 11.12 与父母关系选项改名（2026-10-08）

「与父母关系」选项由「与父母同住 / 就近居住 / 异地 / 其他」改名为「与其同住 / 同城居住 / 脱离关系 / 父母双亡」（用户指定；按位映射，4 键数量与布局不变），全部就地编辑，画布零手动改动：

- `profile-wizard-3.html`：分段控件 4 键文案按位替换（与其同住 / 同城居住 / 脱离关系 / 父母双亡），dom-id 全沿用 `parent-together` / `parent-nearby` / `parent-remote` / `parent-other`，2×2 网格与 JS 分组数组不变
- `filter.html`：与父母关系筛选组 4 枚复选文案按位同步；「我不能接受」中性组的「与父母同住」胶囊属另一维度（dealbreaker），未受影响
- `my-profile.html`：展示行示例值「就近居住」→「同城居住」；`profile-detail.html`：安然示例胶囊「与父母异地」→「同城居住」（新选项集中最接近的良性取值；原「异地」概念已从选项集移除）
- dom-id 变化：无（wizard-3 仍 49、filter 仍 50），JSON 本轮零改动
- 校验脚本 v13：检查 8 needle 同步（profile-detail「与父母异地」→「同城居住」），新增检查 17（与其同住 / 脱离关系 / 父母双亡 在 wizard-3 / filter 的 6 个 needle）；完整校验通过（exit 0）

### 11.13 wizard-4 新增「我可提供」多选板块（2026-10-08）

「资料创建 · 照片」页在生活照片模块上方新增「我可提供」板块（用户指定，固定资产类多选），全部就地编辑，画布零手动改动：

- `profile-wizard-4.html`：进度条区块与生活照片标题拆分为独立 section，中间插入「我可提供」板块（h1 标题 + 说明「可多选，勾选你能提供的资源与条件」+ 6 枚胶囊）：车 / 房 / 存款 / 稳定收入 / 本地户口 / 无贷款；dom-id 前缀 `provide-*`（provide-car / provide-house / provide-savings / provide-income / provide-hukou / provide-debt-free）
- 交互：新增 IIFE `[data-dom-id^="provide-"]` 多选 toggle（aria-pressed + 类切换），与 wizard-3「我不能接受」模式一致；页面其余结构（上传网格、底部按钮、lucide 初始化）不动
- dom-id 变化：wizard-4 `domIdsRequired` 8 → 14（新增 6 个 provide-*，插入于 upload-slot-1 之前，与 dom 顺序一致）
- 后续联动候选：my-profile 展示行、filter「我可提供」筛选组、profile-detail 胶囊（待选项定稿后再同步）
- 校验脚本 v14：新增检查 18（我可提供标题 / 说明文案 / 6 个 provide-* dom-id / 存款 / 稳定收入 / 本地户口 / 无贷款 / toggle 选择器在 wizard-4 的 13 个 needle）；完整校验通过（exit 0）

### 11.14 wizard-1 新增婚姻状态与子女情况（2026-10-08）

「资料创建 · 基础」页在职业字段之后新增「婚姻状态」与「子女情况」两个分段单选字段（用户指定婚姻状态选项；子女情况选项按抚养归属维度设计），全部就地编辑，画布零手动改动：

- `profile-wizard-1.html`：婚姻状态 2 键（未婚 / 离异，`marriage-unmarried` / `marriage-divorced`，grid-cols-2）；子女情况 3 键（无子女 / 有子女随我 / 有子女不随我，`children-none` / `children-with-me` / `children-not-with-me`，grid-cols-3）；两字段均沿用 wizard-3 分段样式（banban-text-body / py-2.5 / bg-input 容器）
- 交互：页面 JS 由单一 gender 切换重构为 `segmentGroups` 分组循环（`.gender-btn` / `.marriage-btn` / `.kids-btn` 三组各自单选），性别交互行为不变
- 语义边界：wizard-3「伴侣状态」（未婚无伴侣 / 已婚分居 / …）是意向维度的现状，与基础信息的婚姻历史（未婚 / 离异）为不同维度，两字段并存；子女情况与 wizard-3「生育意愿」（要不要孩子）分别为现状与意愿维度
- dom-id 变化：wizard-1 `domIdsRequired` 7 → 12（新增 5 个，插入于 input-job 之后、btn-next 之前，与 dom 顺序一致）
- 后续联动候选：my-profile 展示行、filter 婚姻/子女筛选组、profile-detail 信息区（待用户确认选项后再同步）
- 校验脚本 v15：新增检查 19（婚姻状态 / 未婚 / 离异 / 子女情况 / 无子女 / 有子女随我 / 有子女不随我 / marriage-divorced / children-not-with-me / '.kids-btn' 在 wizard-1 的 10 个 needle）；完整校验通过（exit 0）

### 11.15 试用期财务管理同步至我的资料（2026-10-08）

用户在画布选中「试用期财务管理」字段并要求同步到其他页面。该字段此前已覆盖 wizard-3 / filter / home / profile-detail（§11.5），唯一缺口为 my-profile 展示行，本轮补齐：

- `my-profile.html`：在「与父母关系」与「正式关系后财务管理」行之间插入「试用期财务管理 / AA」展示行，与后者的示例值 AA 形成试用期 → 正式关系的完整阶梯；展示行无 dom-id，与页内其他行一致
- dom-id 变化：无，JSON 本轮零改动
- 校验脚本 v16：检查 14 新增 needle（my-profile「试用期财务管理」），该检查覆盖面从 wizard3/filter/home/detail 扩展为含 my-profile；完整校验通过（exit 0）

### 11.16 我可提供扩展为分类资源板（2026-10-08）

用户要求将 wizard-4「我可提供」由 6 个平铺芯片扩展为一个分类资源板，全部就地编辑，画布零手动改动（grep 确认 BanBan.design 无任何 provide-* 交互引用）：

- `profile-wizard-4.html`：重构为 5 个子组
  - 出行工具（多选）：无（`transport-none`，`data-exclusive` 组内互斥）/ 小车 / 电动车 / 自行车 / 打车报销；小车、电动车、自行车选中后显示数量步进器（min 1），打车报销选中后显示「月额度 ¥___ 元 / 月」输入行（`transport-taxi-quota`）
  - 居住情况（多选）：在供房 / 全款房（选中后显示数量步进器）、合租房 / 独租房（选中后显示剩余房间数步进器）
  - 居住条件（多选）：商品房 / 商业别墅 / Loft / 村屋 / 地下室 / 私家花园 / 固定车位（措辞为助手拟定，可再调）
  - 资源：保留原 4 芯片 存款 / 稳定收入 / 本地户口 / 无贷款（`provide-savings` / `provide-income` / `provide-hukou` / `provide-debt-free`）
  - 其他：标签式录入，输入框 + 添加按钮 / 回车均可添加，trim、最长 12 字、按 `data-tag` 去重，生成可删除胶囊（`bg-primary/10`）
- 交互：JS 重构为芯片切换（`data-chip-toggle`，选中态 `bg-primary text-primary-foreground`）+ 分组互斥（`data-chip-group` 内 closest 查找）+ 步进器（`data-stepper` / `data-step` / `data-count`）+ 额度行与步进器显隐（`data-qty-for` / `data-quota-for` 映射 + 新增 `.bb-hidden` 工具类）+ `addOtherTag()` 标签录入
- 文案：说明句更新为「可多选，按分类勾选你能提供的资源与条件」
- dom-id 变化：wizard-4 `domIdsRequired` 14 → 39（移除 provide-car / provide-house，新增 transport-* 9、housing-* 8、cond-* 7、provide-other-* 3，按 dom 顺序排列；原 4 个资源芯片与 upload-slot-1..6、btn-prev、btn-finish 不变）
- 校验脚本 v17：检查 18 针点更新（新说明句、组标签、板内 dom-id，移除 provide-car / provide-house）+ 新增检查 20（`.bb-hidden` / `data-chip-toggle` / `data-exclusive` / `data-chip-group` / `data-stepper` / `data-step` / `data-qty-for` / `data-quota-for` / `addOtherTag` 共 10 个 JS/结构 needle）；完整校验通过（exit 0）

### 11.17 居住情况改为统一未使用房间数（2026-10-08）

用户在画布选中居住情况组反馈：选完在供房 / 全款房 / 合租房 / 独租房后，统一填一个「可提供未使用房间数」即可，可以填 0。本轮把居住情况的 4 个独立步进器合并为 1 个共享步进器行，全部就地编辑，画布零手动改动（grep 确认无 housing-* / transport-* 交互引用）：

- `profile-wizard-4.html`：在供房 / 全款房 / 合租房 / 独租房 4 个芯片保留纯多选，删除各自内联步进器；组底部新增共享行「可提供未使用房间数（可填 0）」（`housing-unused-rooms`），初始值 0、下限 0，任一居住情况芯片选中即显示、全部取消即隐藏，切换芯片时数值保留
- 交互：`setChip` 增加组级显隐同步——芯片所在 `[data-chip-group]` 内存在 `[data-reveal-when-selected]` 元素时，按组内是否有选中芯片切换 `.bb-hidden`；步进器 JS 支持 `data-min` 属性（缺省仍为 1，居住情况行 `data-min="0"`）
- dom-id 变化：wizard-4 `domIdsRequired` 39 → 36（移除 housing-mortgage-qty / housing-owned-qty / housing-shared-rooms / housing-rent-rooms，新增 housing-unused-rooms）
- 校验脚本 v18：检查 18 针点替换（housing-mortgage-qty → housing-unused-rooms，housing-shared-rooms → 可提供未使用房间数）+ 检查 20 新增 `data-reveal-when-selected` / `data-min="0"` 两个 needle；完整校验通过（exit 0）

### 11.18 伴侣状态更名并改选项（2026-10-08）

用户在画布选中 wizard-3 伴侣状态字段，要求标题改为「可接受伴侣状态」，选项改为 未婚无伴侣 / 有同性伴侣 / 离异。字段语义由现状维度转为可接受（筛选）维度，全部就地编辑，画布零手动改动（grep 确认 BanBan.design 无 status-* 交互引用）：

- `profile-wizard-3.html`：标签 伴侣状态 → 可接受伴侣状态；已婚分居（`status-separated`）→ 有同性伴侣（`status-same-sex-partner`）；未婚无伴侣（`status-unmarried`）/ 离异（`status-divorced`）不变；grid-cols-3 分段与 JS 分组（`.status-btn` 经 segmentGroups 循环）不变
- `filter.html`：筛选组标签同步 → 可接受伴侣状态；`filter-status-separated` → `filter-status-same-sex-partner`，标签文本同步
- `my-profile.html`：搭伴意向卡片展示行 伴侣状态 → 可接受伴侣状态，示例值 未婚无伴侣 仍为新选项之一，保留
- 语义边界：wizard-1「婚姻状态」（未婚 / 离异，本人历史）不受影响；wizard-3「搭伴对象」（异性 / 同性 / 不限，形式维度）不受影响；profile-detail 无该字段展示行（原本就没有），无需改动
- dom-id 变化：wizard-3 `domIdsRequired` 总数不变（status-separated → status-same-sex-partner）；filter 同理（filter-status-separated → filter-status-same-sex-partner）
- 校验脚本 v19：检查 10（status-seek）针点扩展——wizard-3 / filter / my-profile 三处 可接受伴侣状态 标签 + 两个新 dom-id，my-profile 旧 needle 伴侣状态 替换为 可接受伴侣状态；完整校验通过（exit 0）

### 11.19 新增搭伴方向字段（2026-10-08）

用户要求在 wizard-3「可接受伴侣状态」上方新增「搭伴方向」字段，选项为 领证结婚 / 协议搭伴 / 自由式。全部就地编辑，画布零手动改动：

- `profile-wizard-3.html`：表单首位（可接受伴侣状态之前）新增 搭伴方向 grid-cols-3 分段组，dom-id `direction-marriage` / `direction-agreement` / `direction-freestyle`；JS 分段互斥 groups 数组追加 `'direction'`（沿用 `[data-dom-id^="direction-"]` 前缀选择器）
- `filter.html`：在 可接受伴侣状态 组上方新增 搭伴方向 多选标签组（`filter-direction-marriage` / `filter-direction-agreement` / `filter-direction-freestyle`）
- `my-profile.html`：搭伴意向卡片在 可接受伴侣状态 行上方新增「搭伴方向 / 协议搭伴」展示行（示例值与 detail 胶囊一致）
- `profile-detail.html`：搭伴意向胶囊组首位新增「协议搭伴」胶囊
- dom-id 变化：wizard-3 `domIdsRequired` +3、filter +3，均按 dom 顺序插入对应位置
- 校验脚本 v20：检查 10 针点扩展（三页 搭伴方向 标签 + 4 个新 dom-id needle + profile-detail 协议搭伴 胶囊），JS groups 数组 needle 更新为含 `'direction'` 的新串；完整校验通过（exit 0）

### 11.20 风格切换至苹果设计语言（2026-10-08）

用户要求「现在把风格调整好」，参照 Apple Design Library 将整体视觉从 Sage 暖灰绿切换为苹果系统设计语言。仅做令牌值级替换，页面 body 结构、文案、dom-id 与交互逻辑零改动，画布零手动改动：

- `colors_and_type.css`：品牌色板替换为苹果系统色——primary-500 `#6B8E7D → #007AFF`（400 `#2E8DFF`，600–950 同步重算）、中性阶替换为 iOS 系统灰（0 `#FFFFFF` … 950 `#0A0A0C`）、语义色替换为系统色（success `#34C759` / warning `#FF9500` / error `#FF3B30` / info `#007AFF`）；深色块（默认外观）背景 `#0E100F → #000000`、foreground `#F5F5F7`、card/muted `#1C1C1E`、popover/border/input `#3A3A3C`、muted-foreground `#8E8E93`，阴影透明度按苹果深色面板调深（0.30 / 0.50 / 0.60）
- 18 个页面 `<style id="theme-vars">`：整体替换为新 `colors_and_type.css` 内容（与品牌 CSS 一致）；head 注入 `<meta name="theme-color" content="#000000">`
- `profile-detail.html`：DiceBear 头像背景参数 `backgroundColor=232823 → 1c1c1e`（页面 body 级唯一改动，`<img src>` 白名单例外）
- 不变项：`--banban-*` 令牌命名、字体栈、圆角 4/8/12/9999px、排版类、`.dark` 外观、全部 dom-id 与 JS 交互
- 校验脚本 v21：docstring 追加记录，检查 7 背景针点 `#0e100f → #000000`；完整校验通过（exit 0）

## 12. 开发交接包（dev-handoff）（2026-10-08）

设计定稿后新增 `dev-handoff/` 目录，为 iOS 接入团队提供"设计源 → 原生实现"的翻译层。本包只读设计源（18 页 HTML / `colors_and_type.css` / 画布），零设计文件改动：

- **README.md**：目的与范围、文件清单与阅读顺序、约束与不变项、校验闭环约定
- **01-design-tokens.md**：CSS ↔ Swift 令牌映射（13 项语义动态色表、状态色 12 项、品牌/中性阶全表、级联沿用规则、排版映射、圆角/阴影折算、Swift 命名对照）；修正 §4 mutedForeground 表述（按 3.1 表口径：`.dark` 覆盖、两分支同值、保持动态实现）
- **02-component-inventory.md**：三层提取（结构层 class 词频 / 注册层 domIdsRequired 255 / 行为层 63 交互）+ 22 项组件总表 + Lucide→SF Symbols 对照 46 种 + 组件×18 页矩阵
- **03-interaction-specs.md**：63 条画布交互逐页明细（trigger → target → SwiftUI 导航建议 push/sheet/fullScreenCover/TabView/root-replace/self）+ 5 类页内状态管理建议（分段单选/芯片多选/步进器与滑块/标签录入/说明浮窗）+ 开关与文本输入补充；有意保留的返回方向差异已披露（safety 回 my-profile vs privacy 回 settings）
- **04-validation-and-loop.md**：校验运行方式（`VALIDATION PASSED` + exit 0）、v22 检查 21 针点清单、v1→v22 历史索引（指向 §11）、开发期红线（先修源再升版、禁止删检查、画布↔03 镜像、CSS↔Swift 镜像）
- **Tokens/BanBanTokens.swift**：单文件令牌实现（`UIColor(dynamicProvider:)` 双外观、深色为默认分支、`Color(uiColor:)` 桥接、自带 `UIColor(hex:)`）；命名与 01 §7 严格一致；radius = CSS blur ÷ 2；CSS 负 spread 无 SwiftUI 原生对应已在注释披露；编译级验证由接入方 Xcode 首编完成

校验脚本升级 **v22**：新增检查 21 守护本包完整性（6 文件存在、Swift 色值锚点 `#007AFF/#2E8DFF/#000000/#1C1C1E/#3A3A3C/#F5F5F7`、文档锚点、画布 `devMetadata.interactions` 总数断言 `== 63`、swiftc 可用时附加 `-parse`）；完整校验通过（exit 0）。
