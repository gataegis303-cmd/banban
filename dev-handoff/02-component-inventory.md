# 02 组件清单（HTML 原型 → SwiftUI）

> 提取范围：`../pages/*.html`（18 页）+ `../runtime-orchestration-summary.json` + `../BanBan.design`。本文档是当前定稿的快照；设计改动后以代码与画布为准。

## 1. 三层提取方法

组件清单按三层证据交叉提取，避免凭印象归组：

| 层 | 证据源 | 提取内容 |
| --- | --- | --- |
| 结构层 | 18 页 HTML 的 class 词频与 dom-id | 组件骨架（如 `bg-card` 容器 147 处、`rounded-full` 胶囊 200 处）与状态类（`active:bg-muted` 按压态 40 处、`focus:ring-2` 焦点环 23 处） |
| 注册层 | `../runtime-orchestration-summary.json` 的 `domIdsRequired`（共 **255** 个必选锚点） | 哪些节点是行为契约（画布交互与校验脚本的对账口径） |
| 行为层 | `../BanBan.design` 的 `devMetadata.interactions`（**63** 条）+ 页内 JS 标记（`segment-btn` ×30、`tag-checkbox` ×46、`data-chip-group`、`data-stepper`） | 组件的交互形态（单选 / 多选 / 独占 / 步进 / 浮窗） |

**dom-id 计数口径**：`domIdsRequired` 255 个是画布与校验的对账集合；HTML 原生 `id` 另含 2 个样式元素锚点（`theme-vars` / `semantic-token-fallback`）与少数响应式重复（如 `filter` 的 `range-age-*` 桌面/移动双份、wizard-3 的 `input-intent-city` 双份），均不计入组件矩阵。

**各页 domIdsRequired 分布**（校验脚本检查 5 逐一对账）：

| 页面 | 必选 dom-id | 页面 | 必选 dom-id |
| --- | --- | --- | --- |
| 启动页 | 2 | 推荐首页 | 10 |
| 手机号登录 | 4 | 筛选面板 | 53 |
| 实名认证 | 4 | 他人资料 | 6 |
| 权限请求 | 5 | 匹配成功 | 4 |
| 资料创建 · 基础 | 12 | 消息列表 | 9 |
| 资料创建 · 生活 | 15 | 聊天界面 | 5 |
| 资料创建 · 意向 | 52 | 安全中心 | 9 |
| 资料创建 · 照片 | 36 | 隐私设置 | 9 |
| 我的资料 | 6 | 设置 | 14 |

## 2. 组件总表（22 项）

| # | 组件 | 出处页 | 结构特征 | 关键 dom-id | SwiftUI 映射 | 状态变体 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 顶部导航栏 | 登录/实名/资2/资3/筛选/他人/聊天/安全/隐私/设置（10 页） | `sticky top-0` 吸顶，左返回 + 中标题 + 右动作 | `btn-back`、`btn-close`、`btn-more`、`btn-report` | `NavigationStack` + `.toolbar`，或自定义 `HStack` + `Shadow` | 滚动后加 `shadow-sm`（shadow-1） |
| 2 | 底部标签栏 | 资料/首页/消息/安全/隐私/设置（6 页） | `fixed bottom-0`，4 栏图标+文字，当前项 `text-primary` | `nav-home`、`nav-messages`、`nav-square`、`nav-profile` | `TabView` + `.tabItem` | 选中 / 未选中；广场为占位（`nav-square` → 首页，见 `../handoff.md` §5） |
| 3 | 推荐卡片 | 首页 | 大圆角卡 `bg-card` + 头像 + 信息行 + 徽章 | `card-detail`、`card-avatar` | `ZStack` 卡片 + 手势（`../handoff.md` §7.2 种子） | 默认 / 按压（`active:bg-muted`） |
| 4 | 列表行组 | 安全/设置 | `bg-card` 容器 + `border-b` 分隔 + `last:border-b-0`（Inset Grouped 观感） | `row-phone`、`row-verify`、`row-reports`、`row-emergency`… | `List(.insetGrouped)` 或自定义行组 | 普通 / 危险（`btn-logout` 红字 → `Color.banbanError`） |
| 5 | 开关行 | 权限/隐私/设置 | 行内标签 + 右侧开关（`bg-input` 轨道） | `toggle-msg/match/activity/dark`、`toggle-location/notification/photos`、`toggle-certified-only/hide-distance/hide-online/phone-search` | `Toggle(isOn:)` | on / off |
| 6 | 分段单选组 | 资1/资2/资3 | `grid` 多列按钮，JS `segmentGroups` 互斥 | `gender-*`、`marriage-*`、`children-*`、`direction-*`、`status-*`、`seek-*`、`live-*`、`finance-*`、`wealth-*`、`child-*`、`social-*`、`parent-*`、`smoking-*` 等 | `Picker(.segmented)` 或自定义网格（状态管理见 03 §4.1） | 选中 `bg-primary`/`text-primary-foreground`，未选中 `bg-card` |
| 7 | 芯片 / 标签 | 资3/资4/筛选（可交互）；首页/他人（展示） | 胶囊 `rounded-full`，多选 `aria-pressed` / CSS `:checked` | `no-*` ×15、`filter-no-*` ×15、`provide-*`、`cond-*`、`filter-direction-*`… | 自定义胶囊 Button + `Set<String>` 状态（见 03 §4.2） | 选中 / 未选中；组内独占位（`data-exclusive`，如 `transport-none`） |
| 8 | 步进器 | 资4 | − 数值 + 横排；`data-stepper` / `data-qty-for` / `data-min` | `transport-sedan-qty`、`transport-ebike-qty`、`transport-bike-qty`、`housing-unused-rooms` | `Stepper(value:in:)` | 边界禁用（最小值可为 0，`data-min="0"`） |
| 9 | 额度输入 | 资4 | 打车月额度文本输入 | `transport-taxi-quota` | `TextField` + `.decimalPad` | 空 / 已填 |
| 10 | 文本输入框 | 登录/资1/资3/资4/聊天/筛选 | `bg-input` 圆角填充，聚焦环 `focus:ring-ring/40` | `input-phone`、`input-nickname`、`input-birthdate`、`input-city`、`input-job`、`input-intent-city`、`input-message`、`provide-other-input` | `TextField` | 默认 / 聚焦（ring） |
| 11 | 主按钮 | 全站 14 页 | `bg-primary` + `text-primary-foreground` + `rounded-radius-md` + `py-3.5` | `btn-next`、`btn-finish`、`btn-get-code`、`btn-apply`、`btn-enter`、`btn-like`、`btn-message`、`btn-send`… | `Button` + 自定义 `ButtonStyle`（`BanBanRadius.medium`） | 默认 / 按压 |
| 12 | 次级 / 危险按钮 | 全站 | `text-primary` 或 `bg-muted`；危险态红字 | `btn-skip`、`btn-prev`、`btn-back`、`btn-reset`、`btn-clear-cache`、`btn-logout` | `Button(.borderless)`；危险变体 `foregroundStyle(Color.banbanError)` | 普通 / 危险 |
| 13 | 进度指示 | 资1–资4 | 顶部步骤圆点 `h-2/w-2` + 进度条 | 无（装饰性） | `ProgressView` + 自定义圆点 | 当前 / 已完成 / 未到 |
| 14 | 安全横幅 | 聊天 | subtle 底 + 图标 + 多行文案（`warning-subtle` 类） | 无（样式类） | 自定义 `HStack`（`BanBanColor.*Subtle` 四色变体） | success / warning / error / info 四色 |
| 15 | 聊天气泡 | 聊天 | 双向不对称圆角；我方 `bg-primary`，对方 `bg-card` | 无（结构性） | 自定义气泡视图 | 发送 / 接收 |
| 16 | 头像 | 首页/资料/他人/匹配/消息 | 圆形图，DiceBear 生成占位（**无真人肖像**，`../handoff.md` §6） | `card-avatar`、`avatar-me`、`avatar-user`、`avatar-match` | `AsyncImage` | 尺寸变体；上线为用户上传照 + 生成头像兜底 |
| 17 | 说明浮窗 | 资3 | 全屏半透明背板 + 居中卡片，Esc / 背板 / 按钮三路关闭 | `btn-seek-help`、`help-overlay`、`help-panel`、`help-panel-title`、`btn-seek-help-close` | `.sheet(item:)` 或 overlay（见 03 §4.5） | 打开 / 关闭 |
| 18 | 照片上传格 | 资4 | 虚线格 `grid` 3×2 | `upload-slot-1…6` | `PhotosPicker` | 空 / 已填 |
| 19 | 标签录入 | 资4 | 输入 + 添加按钮 + 可删胶囊列表（trim / 12 字上限 / 去重） | `provide-other-input`、`provide-other-add`、`provide-other-tags` | `TextField` + `onSubmit` + FlowLayout（见 03 §4.4） | 空态 / 已录入 |
| 20 | 空状态 | 消息 | 居中图标 + 标题 + 说明 | `empty-state` | `ContentUnavailableView`（iOS 17+；低版本自绘） | — |
| 21 | 认证徽章 | 首页/他人/隐私 | `badge-check` 图标 + 文本 | 无（图标级） | `Image(systemName:)` 组合 | — |
| 22 | 双端滑块 | 筛选 | 年龄区间 min/max | `range-age-min`、`range-age-max`、`range-age-slider` | 自定义双滑块（无原生对应物） | 拖动中 / 停靠 |

## 3. Lucide → SF Symbols 对照（46 种）

> 原型用 Lucide 线性图标；iOS 端统一换用 SF Symbols（iOS 15+ 基线）。标「近似」者为语义最近似、视觉略有差异的映射，接入时可按团队图标规范微调。使用频次仅统计原型内出现次数，供优先级参考。

| Lucide | SF Symbols | 次数 | | Lucide | SF Symbols | 次数 |
| --- | --- | --- | --- | --- | --- | --- |
| chevron-right | `chevron.right` | 18 | | more-horizontal | `ellipsis` | 1 |
| chevron-left | `chevron.left` | 9 | | more-vertical | `ellipsis`（近似） | 1 |
| user | `person` | 9 | | pencil | `pencil` | 1 |
| map-pin | `mappin` | 6 | | cake | `cake` | 1 |
| home | `house` | 6 | | lock | `lock` | 1 |
| layout-grid | `square.grid.2x2` | 5 | | map-pin-off | `mappin.slash` | 1 |
| badge-check | `checkmark.seal.fill`（近似） | 4 | | eye-off | `eye.slash` | 1 |
| heart | `heart` | 4 | | phone-off | `phone.down` | 1 |
| message-square | `message` | 4 | | info | `info.circle` | 1 |
| image | `photo` | 4 | | coffee | `cup.and.saucer` | 1 |
| message-circle | `bubble.left`（近似） | 3 | | cigarette-off | `smoke`（近似） | 1 |
| check | `checkmark` | 3 | | wine | `wineglass` | 1 |
| shield-check | `checkmark.shield.fill`（近似） | 3 | | moon | `moon` | 1 |
| x | `xmark` | 2 | | images | `photo.on.rectangle`（近似） | 1 |
| sparkles | `sparkles` | 2 | | calendar | `calendar` | 1 |
| bell | `bell` | 2 | | briefcase | `briefcase` | 1 |
| heart-handshake | `hands.and.sparkles`（近似） | 2 | | alert-circle | `exclamationmark.circle` | 1 |
| plus | `plus` | 2 | | check-circle-2 | `checkmark.circle` | 1 |
| chevron-down | `chevron.down` | 1 | | flag | `flag` | 1 |
| sliders-horizontal | `slider.horizontal.3` | 1 | | ban | `nosign`（近似） | 1 |
| arrow-right | `arrow.right` | 1 | | phone | `phone` | 1 |
| message-circle-off | `bubble.left`（近似） | 1 | | help-circle | `questionmark.circle` | 1 |
| send | `paperplane.fill` | 1 | | shield-alert | `exclamationmark.shield.fill`（近似） | 1 |

## 4. 组件 × 18 页矩阵

图例：`●` 可交互 / 结构组件存在；`○` 仅展示形态；`—` 不存在。

| 组件 | 启动 | 登录 | 实名 | 权限 | 资1 | 资2 | 资3 | 资4 | 资料 | 首页 | 筛选 | 他人 | 匹配 | 消息 | 聊天 | 安全 | 隐私 | 设置 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 顶部导航栏 | — | ● | ● | — | — | ● | ● | ● | — | — | ● | ● | — | — | ● | ● | ● | ● |
| 底部标签栏 | — | — | — | — | — | — | — | — | ● | ● | — | — | — | ● | — | ● | ● | ● |
| 推荐卡片 | — | — | — | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — |
| 列表行组 | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ● | — | ● |
| 开关行 | — | — | — | ● | — | — | — | — | — | — | — | — | — | — | — | — | ● | ● |
| 分段单选组 | — | — | — | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — |
| 芯片 / 标签 | — | — | — | — | — | — | ● | ● | — | ○ | ● | ○ | — | — | — | — | — | — |
| 步进器 / 额度 | — | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| 文本输入框 | — | ● | — | — | ● | — | ● | ● | — | — | ● | — | — | — | ● | — | — | — |
| 主按钮 | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | — | ● | — | — | — |
| 次级 / 危险按钮 | ● | ● | ● | ● | ● | ● | ● | ● | — | ● | ● | ● | ● | — | ● | — | — | ● |
| 进度指示 | — | — | — | — | ● | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| 安全横幅 | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ● | — | — | — |
| 聊天气泡 | — | — | — | — | — | — | — | — | — | — | — | — | — | — | ● | — | — | — |
| 头像 | — | — | — | — | — | — | — | — | ● | ● | — | ● | ● | ○ | — | — | — | — |
| 说明浮窗 | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — | — |
| 照片上传格 | — | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| 标签录入 | — | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| 空状态 | — | — | — | — | — | — | — | — | — | — | — | — | — | ● | — | — | — | — |
| 认证徽章 | — | — | — | — | — | — | — | — | — | ○ | — | ○ | — | — | — | — | ○ | — |
| 双端滑块 | — | — | — | — | — | — | — | — | — | — | ● | — | — | — | — | — | — | — |

> 矩阵按 HTML 结构、dom-id 与 Lucide 图标分布核对生成。聊天页头像是消息行内的展示形态（消息页 `○`）；筛选页的 `input-city` 为城市文本输入。
