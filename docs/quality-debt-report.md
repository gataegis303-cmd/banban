# BanBan 质量债偿还总结报告

> 执行周期：2026-10-13 ~ 2026-10-14 · 计划文档：[tasks/plan.md](../tasks/plan.md) · 审查底稿：[docs/security-review.md](./security-review.md)
> 结论：**4 Phase / 11 Task / 4 Checkpoint 全部完成**。安全审查 8 项发现中 5 项修复关闭、3 项记录为接受/待办；新增 pytest 体系 33 个用例全绿；GitHub Actions CI 两 job 在线全绿。

## 一、成果速览

| 维度 | 之前 | 现在 |
|------|------|------|
| 安全审查 | 无 | 全量审查完成，1 高 2 中 5 低分级成文 |
| 安全配置 | `app_debug` 默认开启、secret_key 默认值可静默上产 | 安全默认（debug=False、fail-fast、不信任 XFF） |
| 自动化测试 | 0 | 33 个用例（4 个文件），真实 Postgres + fakeredis，0.8s 跑完 |
| CI | 无 | push main 即触发，backend（ruff+pytest）+ iOS（xcodebuild）双 job 全绿 |
| 顺带修复 | — | `_project_batch` 空资料兜底缺失（列表 500 真 bug）+ 2 个 lint |

## 二、执行轨迹

### Phase 1: 安全审查（Task 1-3）✅

范围 `backend/app` 全量，方法：信任边界分析 + STRIDE + OWASP Top 10 对照。

**发现总表**（8 项，核心鉴权与会话授权面无发现）：

| 编号 | 级别 | 摘要 | 处置 |
|------|------|------|------|
| F1 | **高** | `app_debug` 默认 True：验证码泄露 + SQL echo 打 PII + 微信 dev 直通可接管任意账号 | ✅ 已修复 |
| F2 | 中 | secret_key 默认值无启动校验，生产漏配即 JWT 可伪造 | ✅ 已修复 |
| F3 | 中 | `client_ip` 无条件信任 XFF 首段，限流可被伪造头绕过 | ✅ 已修复 |
| F4 | 低 | refresh token 不轮换、无 reuse detection | 接受（已文档化权衡） |
| F6 | 低 | 日志打手机号全号 PII | ✅ 已修复 |
| F7 | 低 | JWT 无 `aud` 校验 | 接受（单服务场景） |
| F12 | 低 | 身份证号无跨用户唯一性校验 | 接受（风控待办，需表结构变更） |
| F16 | 低 | 验证码用 `random.randint` 非密码安全随机 | ✅ 已修复 |

同时确认了 8 个面无问题：Apple 登录、会话授权（404 不泄露存在性 + FOR UPDATE 串行化）、WS 鉴权、照片上传（无路径穿越面）、设备令牌、CORS、统一错误响应、实名校验。

### Phase 2: 安全修复（Task 4-5）✅

| 修复 | 内容 | 改动点 |
|------|------|------|
| F1 | `app_debug` 默认改 `False`（安全默认）；env 模板显式声明 `APP_DEBUG=true` 保留开发便利 | config.py、.env.example、.env.development.example |
| F2 | 非 debug 且 secret_key 为默认值时**拒绝启动**（fail-fast） | config.py |
| F3 | 新增 `app_trusted_proxy_count`（默认 0 = 用 socket 对端 IP）；反代时取 XFF 倒数第 N 段。uvicorn 双层解析逐形态验证无绕过面 | deps.py、config.py |
| F6 | 日志手机号打码 `138****1234` | sms.py |
| F16 | 验证码改 `secrets.randbelow` | sms.py |

验证：curl 冒烟矩阵回归通过（sms send/verify、token、profile、fail-fast、打码、XFF 语义）。

### Phase 3: 测试补齐（Task 6-9）✅

**架构决策**：测试用真实 Postgres（`banban_test` 独立库）而非 SQLite——代码依赖 PG 方言（`on_conflict_do_update`、UUID、timestamptz）；Redis 用 fakeredis 打桩；每用例事务回滚隔离。

**用例分布**（33 个，0.8s）：

| 文件 | 数量 | 覆盖内容 |
|------|------|------|
| test_auth.py | 17 | sms send/verify、refresh 轮换、logout、device-token upsert/改绑/删除、微信 dev 直通 |
| test_rate_limit.py | 7 | 固定窗口 429、窗口滚动、键 TTL、XFF 按 IP 隔离、sms 自然日/日/IP 上限 |
| test_chat_push_filter.py | 7 | 未读累加、历史与已读、非参与方 404、离线才推（hub 分支 + APNs payload 全断言）、filter 默认/覆盖 |
| test_smoke.py | 2 | health 就绪、sms send 写入 fakeredis |

**测试驱动的真 bug 修复**：`_project_batch` 对「注册后未填资料的用户」直接索引 KeyError → 500，而 docstring 设计意图是内存空对象兜底（不落库）。该函数是 matching 列表/详情与 chat 会话列表三条投影路径的共用件——真实系统里新注册用户一进推荐即触发。已按设计意图修复并用测试锁定。

### Phase 4: CI（Task 10-11）✅

**[.github/workflows/ci.yml](../.github/workflows/ci.yml)**：push / PR 到 main 触发双 job。

- **backend**（ubuntu + postgres:16/redis:7 service 容器）：`uv sync` → `ruff check app tests` → `pytest`；`BANBAN_TEST_DATABASE_URL` 注入 service 容器，建表走 create_all 无需 alembic
- **ios**（macos）：xcodebuild 输出落日志文件，以包含 `** BUILD SUCCEEDED **` 为准（规避 grep 管道退出码误报，与 CLAUDE.md 约定一致）

**首跑失败 → 修复 → 第二轮全绿**：

| 问题 | 根因 | 修复 |
|------|------|------|
| backend job `Set up job` 失败 | `setup-uv@v9` 不存在——该仓库不维护 major tag，仅完整版本号 | pin `@v10.3.0` |
| iOS job xcodebuild exit 65 | app target 引用 `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`，该变量由新版 Xcode 提供，CI 环境展开为空 → deployment target 掉底 → iOS 16+ API 全量报错 | target/project 四处统一为字面量；结合代码事实（`onChange` 双参数闭包为 iOS 17 API）定为 **17.0** |

本地 `** BUILD SUCCEEDED **` 验证后推送，第二轮 [CI success](https://github.com/gataegis303-cmd/banban/actions/runs/38490812513)。

## 三、改动清单（提交记录）

| 提交 | 内容 |
|------|------|
| `fcbb9bd` | fix: 安全审查修复 + 测试补齐 + CI（19 files，+990/-11） |
| `46cc704` | fix: 修复 CI 首跑失败——setup-uv pin 完整版本 + iOS 部署目标定为 17.0 |
| `222f100` | docs: 勾选 Checkpoint 4（CI 全绿） |

新建：conftest.py + 4 测试文件、ci.yml、security-review.md、plan/todo。修改：config.py、deps.py、main.py、sms.py、matching.py、aliyun_realperson.py、pyproject.toml/uv.lock、两个 env 模板、pbxproj。

## 四、遗留事项

1. **接受的安全权衡**（已文档化，触发条件明确）：F4 refresh 轮换（多服务/长会话期需补）、F7 aud 校验（拆分服务时必补）、F12 身份证唯一性（产品风控待办，需 SHA-256 哈希列 + 唯一索引）
2. **iOS 功能收尾**（不在本计划，默认延后）：选图 UI、badge 清零、MockData 切服务端
3. **iOS 无测试**：CI 仅构建验证；Swift 侧无测试基建，后续如补需先决策框架（Swift Testing / XCTest）
4. **小坑备忘**：`setup-uv` 仓库只认完整版本号 tag；Xcode 新模板的 `RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET` 变量跨环境不可移植，工程配置一律写字面量
