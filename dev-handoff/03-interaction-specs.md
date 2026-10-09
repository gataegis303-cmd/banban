# 03 · 交互规格（63 条画布交互 → SwiftUI 映射）

> 数据源：`BanBan.design` 画布 `devMetadata.interactions`（每条 = trigger.domId → navigate:target），总数 **63**，与 18 页 HTML 注册层一致。本文是原生端交互实现的唯一权威明细；导航结构图见 `../handoff.md` §4（4.1 启动与登录链 / 4.2 资料创建向导链 / 4.3 主 Tab 流 / 4.4 内容与匹配流 / 4.5 设置与安全链），此处不重复绘制。

## 1. 总览

| 页面 | 条数 | 页面 | 条数 |
| --- | --- | --- | --- |
| 启动页 onboarding | 2 | 推荐首页 home | 8 |
| 手机号登录 login | 2 | 筛选面板 filter | 3 |
| 实名认证 verify-id | 2 | 他人资料 profile-detail | 3 |
| 权限请求 permissions | 2 | 匹配成功 match-success | 2 |
| 向导 1（基础） | 1 | 消息列表 messages | 8 |
| 向导 2（生活） | 2 | 聊天界面 chat | 3 |
| 向导 3（意向） | 2 | 安全中心 safety | 6 |
| 向导 4（照片/资源） | 2 | 隐私设置 privacy | 5 |
| 我的资料 my-profile | 5 | 设置 settings | 5 |
| | | **合计** | **63** |

> 四向导页合计仅 7 条**画布级**导航交互——向导内部的分组选择、步进器、标签录入等是**页面内状态**，不产生导航，见本文第 4 章。

## 2. 导航方式约定（SwiftUI 建议）

| 记号 | 含义 |
| --- | --- |
| `push` | `NavigationStack` 入栈（系统返回手势可用） |
| `pop` | 出栈返回上一页 |
| `dismiss` | 关闭模态（sheet / fullScreenCover） |
| `sheet` | `.sheet` 半模态（可保留上下文，如筛选、说明浮窗） |
| `fullScreenCover` | 全屏模态（仪式感节点：匹配成功；或整体流程：编辑资料） |
| `tab` | 主 TabView 切换（不产生新的导航栈节点） |
| `root-replace` | 登出等场景：清空导航栈回到根 |
| `self` | 不导航，仅页面内状态变化（发送消息、重置筛选、下张卡片） |

## 3. 逐页明细（trigger → target → SwiftUI 建议）

### 3.1 启动链

| 页面 | 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- | --- |
| onboarding | `btn-start` | page-login | 开始使用 | push |
| onboarding | `btn-login` | page-login | 已有账号登录 | push |
| login | `btn-get-code` | page-verify-id | 获取验证码 | push |
| login | `btn-back` | page-onboarding | 返回 | pop |
| verify-id | `btn-continue` | page-permissions | 验证通过继续 | push |
| verify-id | `btn-close` | page-login | 关闭回到登录 | pop |
| permissions | `btn-enter` | page-profile-wizard-1 | 授权进入 | push |
| permissions | `btn-skip` | page-profile-wizard-1 | 跳过权限 | push |

### 3.2 资料创建向导链（wizard-1 → 4 线性流）

| 页面 | 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- | --- |
| wizard-1 | `btn-next` | page-profile-wizard-2 | 下一步（校验通过） | push |
| wizard-2 | `btn-prev` | page-profile-wizard-1 | 上一步 | pop |
| wizard-2 | `btn-next` | page-profile-wizard-3 | 下一步 | push |
| wizard-3 | `btn-prev` | page-profile-wizard-2 | 上一步 | pop |
| wizard-3 | `btn-next` | page-profile-wizard-4 | 下一步 | push |
| wizard-4 | `btn-prev` | page-profile-wizard-3 | 上一步 | pop |
| wizard-4 | `btn-finish` | page-my-profile | 完成创建 | root-replace（初次注册）或 fullScreenCover-dismiss（编辑态） |

> `my-profile.btn-edit` 会重新进入 wizard-1（见 3.4）。原生建议：注册态向导走 push 流；编辑态用 `fullScreenCover` 包一层同构向导，`btn-finish` 直接 dismiss 回 my-profile。两条路径复用同一组向导视图。

### 3.3 主 Tab 流（nav-* 四键，出现在 my-profile / home / messages / safety / privacy / settings 六页）

| 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- |
| `nav-home` | page-home | 推荐 | tab（TabView 第 1 tab） |
| `nav-messages` | page-messages | 消息 | tab（第 2 tab） |
| `nav-square` | page-home | 广场（占位） | tab（**占位**：原型尚未拆分广场页，暂指 home；原生端建议预留第 3 tab 枚举位） |
| `nav-profile` | page-my-profile | 我的 | tab（第 4 tab） |

### 3.4 内容与匹配流

| 页面 | 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- | --- |
| my-profile | `btn-edit` | page-profile-wizard-1 | 编辑资料 | fullScreenCover（复用向导，见 3.2 注） |
| home | `card-detail` | page-profile-detail | 查看他人资料 | push |
| home | `btn-filter` | page-filter | 打开筛选 | sheet |
| home | `btn-like` | page-match-success | 喜欢并匹配 | fullScreenCover |
| home | `btn-skip` | page-home | 换下一位 | self（卡片堆栈切换，无导航） |
| filter | `btn-back` | page-home | 返回 | dismiss |
| filter | `btn-apply` | page-home | 应用筛选 | dismiss（先落盘筛选状态再关闭） |
| filter | `btn-reset` | page-filter | 重置 | self（仅恢复默认值，不关闭面板） |
| profile-detail | `btn-back` | page-home | 返回 | pop |
| profile-detail | `btn-like` | page-match-success | 喜欢 | fullScreenCover |
| profile-detail | `btn-skip` | page-home | 换下一位 | pop |
| match-success | `btn-message` | page-chat | 去聊天 | dismiss 后 push 进 chat |
| match-success | `btn-continue` | page-home | 继续逛 | dismiss |

### 3.5 消息与聊天

| 页面 | 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- | --- |
| messages | `chat-1` | page-chat | 打开会话 1 | push |
| messages | `chat-2` | page-chat | 打开会话 2 | push |
| messages | `tab-chat` | page-messages | 切到消息 tab | self（页内分段切换） |
| messages | `tab-likes` | page-messages | 切到喜欢 tab | self（页内分段切换） |
| chat | `btn-back` | page-messages | 返回列表 | pop |
| chat | `btn-report` | page-safety | 举报 → 安全中心 | push |
| chat | `btn-send` | page-chat | 发送消息 | self（追加气泡，无导航） |

### 3.6 设置与安全链

| 页面 | 触发 dom-id | 目标 | 语义 | SwiftUI 建议 |
| --- | --- | --- | --- | --- |
| settings | `btn-back` | page-my-profile | 返回 | pop |
| settings | `row-privacy` | page-privacy | 隐私设置 | push |
| settings | `row-verify` | page-verify-id | 重新实名认证 | push（复用认证页；认证页 `btn-close` 回 login 仅属注册语境，编辑态建议 dismiss） |
| settings | `btn-logout` | page-onboarding | 退出登录 | root-replace（清栈回启动页） |
| privacy | `btn-back` | page-settings | 返回设置 | pop |
| safety | `btn-back` | page-my-profile | 返回我的 | pop |
| safety | `row-emergency` | page-settings | 紧急联系 → 设置 | push |

> **返回方向披露**（有意差异，勿"顺手统一"）：privacy `btn-back` → settings，而 safety `btn-back` → my-profile——原型中 safety 可从 chat 举报链与 my-profile 两个入口到达，画布选择了固定回 my-profile。原生端如改为「回上一页」，需同步更新画布与本文。

## 4. 页面内状态管理（非导航交互）

以下 5 类覆盖向导与筛选页的全部页内控件；dom-id 以 `wizard-3` / `filter`（同名后缀组）、`wizard-4` 为主要出处。

### 4.1 分段单选（segment / radio 组）

- 出处：wizard-1 `gender-male/female`、`marriage-*`、`children-*`；wizard-2 `smoking-*`、`drinking-*`、`sleep-*`、`pet-*`；wizard-3 `direction-*`、`status-*`、`seek-*`、`live-*`、`finance-*`、`social-*`、`parent-*`；filter 同名后缀组（`filter-` 前缀）；wizard-4 `housing-*`、`cond-*`。
- 规则：组内互斥、必选其一（原型默认无选中态，首进可空）。
- SwiftUI：`@State var selection: OptionEnum?` + 自定义胶囊按钮组（`.banbanPrimary` 选中底）；筛选项与向导共用同一 `enum`，保证 filter 与 wizard-3 数据对齐（同后缀同名）。

### 4.2 芯片多选（tag-checkbox）

- 出处：wizard-3 `no-*` 12 项「我不能接受」；wizard-4 `provide-*` 资源标签；filter `pet-*`、`child-*` 等多义组。
- 规则：可多选可反选，`Set<Tag>` 存储；「不能接受」与「我可提供」均为白名单标签。
- SwiftUI：`Set<Tag>` + `FlowLayout` 芯片（选中 `.banbanPrimarySubtle` 底）；删除即从 Set 移除。

### 4.3 步进器与滑块

- 出处：wizard-4 `transport-sedan/ebike/bike-qty`（数量）、`transport-taxi-quota`（月额度）、`housing-unused-rooms`（`data-min=0`）；filter `range-age-min/max` + `range-age-slider`（年龄区间）。
- 规则：数量类下限 0；年龄区间为双端滑块，min ≤ max。
- SwiftUI：`Stepper` 或 +/- 自定义；年龄区间用自定义双 thumb `RangeSlider`（原型是两个 `range input` + 一个视觉滑轨，原生需合并为一个控件）。

### 4.4 标签录入（输入 + 添加 + 已选列表）

- 出处：wizard-4 `provide-other-input` / `provide-other-add` / `provide-other-tags`（「其他可提供」自由标签）。
- 规则：输入非空才可添加；添加后清空输入框；已选标签可单个删除。
- SwiftUI：`TextField` + 提交按钮 + 4.2 的芯片列表；建议加长度上限（如 12 字）与重复去重。

### 4.5 说明浮窗（帮助面板）

- 出处：wizard-3 `btn-seek-help`（打开）、`help-overlay`（遮罩）、`help-panel` + `help-panel-title`（面板）、`btn-seek-help-close`（关闭）；「搭伴方向」求助说明。
- 规则：遮罩点击与关闭按钮均可关闭；浮窗打开期间页内选择暂停交互。
- SwiftUI：`.sheet` + `presentationDetents([.medium])`（或 `.popover`），遮罩手势关闭；不要用 `fullScreenCover`（面板高度小于半屏）。

### 4.6 补充：开关与文本输入

- 开关（`Toggle(isOn:)`）：permissions `toggle-location/notification/photos`；privacy `toggle-certified-only/hide-distance/hide-online/phone-search`；settings `toggle-msg/match/activity/dark`（`toggle-dark` 驱动 `preferredColorScheme`，对应 CSS `.dark` 级联）。
- 文本输入：login `phone` / `input-phone`、`chk-agreement`（须勾选方可获取验证码）；wizard-1 `input-nickname`、`input-birthdate`（日期选择器）、`input-city`、`input-job`；wizard-3 `input-intent-city`；chat `input-message`（焦点时避让键盘）。
