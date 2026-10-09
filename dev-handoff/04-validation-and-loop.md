# 04 · 校验与闭环（开发期如何守护这份交接包）

> 本包不是"拷贝完就结束"的静态文档：仓库内置官方校验脚本，任何对设计源（18 页 HTML / `colors_and_type.css` / 画布）与本包的修改都必须重新通过校验。本文说明运行方式、当前版本（v22）的检查 21 针点清单、历史版本索引，以及开发期的修改纪律。

## 1. 运行方式

```bash
/usr/bin/python3 /Users/mia.369/Documents/Trae/Love/.trae/validate_banban.py; echo "EXIT:$?"
```

- **通过标准**：末行输出 `VALIDATION PASSED`，`EXIT:0`。
- **失败表现**：`VALIDATION FAILED` + 逐条 error，`EXIT:1`；每条 error 都带页面/文件定位，按提示修源即可。
- 运行环境：仅 Python 3 标准库，无需安装依赖；macOS 自带 python3 即可（不要用其他解释器口径）。

## 2. v22 检查 21 针点清单（dev-handoff 完整性）

v22 在原有 20 组检查之上新增**检查 21**，专门守护本包（只读设计源，不改动 HTML/JSON/画布）：

1. **六件套存在**：`README.md`、`01-design-tokens.md`、`02-component-inventory.md`、`03-interaction-specs.md`、`04-validation-and-loop.md`、`Tokens/BanBanTokens.swift` 均存在于 `dev-handoff/`。
2. **Swift 色值锚点**（仅扫描 dev-handoff 内文件，hex 需大写）：`#007AFF`、`#2E8DFF`、`#000000`、`#1C1C1E`、`#3A3A3C`、`#F5F5F7`——覆盖浅/深两套外观的关键语义色（primary 双值、background/card/popover 深色系、foreground 深色值）。
3. **文档锚点**：01 含 SwiftUI 映射关键词（如 `dynamicProvider` 所在的令牌章节口径）、02 含 `domIdsRequired`（注册层口径）、03 含 `63`（交互总数口径）、04 含 `validate_banban.py`（本文件自检）。
4. **画布断言**：`devMetadata.interactions` 18 页合计 **`== 63`**，与 03 的明细表互为镜像——画布交互增删必须同步改 03。
5. **Swift 语法（可选）**：接入环境若有 swiftc，附加 `-parse` 快速语法检查；无 swiftc 则跳过（编译级验证由接入方在 Xcode 首次编译完成，属接入方责任，不属于本仓库门禁）。

其余检查 1–20（页面齐全、JSON 可解析、domIdsRequired 与 HTML 对齐、暗色令牌、各业务标记组等）口径见 `README.md` §4 与历史索引。

## 3. 版本历史索引（v1 → v22）

- 校验脚本当前为 **v22**；`v1 → v20` 每一版的检查变化、修复内容与业务背景，完整记录于 `../handoff.md` §11（11.1–11.20 逐条对应）。
- `runtime-orchestration-summary.json` 的 `validationHistory` 数组逐次记录每次校验的 checks 明细（当前 21 条历史 + 本次 = 22 条），失败项会连同原因一起留痕。
- 本包上线对应 v22：新增检查 21（见上）。此后每次设计源或本包变更，脚本按第 4 章纪律升版。

## 4. 开发期约定（红线）

1. **先修源，再升版**：校验失败永远先改源头（HTML/JSON/画布/本包文档），再把检查口径升级到新版本；**禁止**为让脚本通过而删除、放宽或注释任何既有检查。
2. **升版同步三件套**：脚本 docstring 加版本行 + 新增检查 + `validationHistory` 追加一条 JSON 记录，三者同一次提交完成。
3. **画布 ↔ 03 镜像**：画布交互（当前 63 条）任何增删，必须同步更新 `03-interaction-specs.md` 的明细表与总数；反向亦然。
4. **令牌 ↔ Swift 镜像**：`colors_and_type.css` 令牌变更必须同步 `01-design-tokens.md` 数值表与 `Tokens/BanBanTokens.swift`；Swift 文件头部已声明"勿手改、跟随 CSS 更新"。
5. **Swift 编译验证**：本仓库门禁止步于语法 `-parse`（可选）；完整类型检查、SwiftUI 预览与真机验证由接入方 Xcode 首次编译完成。
