# Implementation Plan: 质量债偿还（安全审查 → 测试 → CI）

## Overview

P1–P13 功能已全部落地。本计划偿还三项质量债：①对后端做全量安全审查并修复发现的问题（交友场景持有身份证/活体等敏感数据）；②搭建 pytest 测试体系覆盖核心链路；③建立 GitHub Actions CI。顺序为审查 → 修复 → 测试 → CI：测试覆盖安全修复后的行为，CI 以测试存在为前提。

## Architecture Decisions

- **测试用真实 Postgres（banban_test 库），不用 SQLite**——模型与代码依赖 PG 方言（`pg_insert on_conflict_do_update`、UUID、timestamptz），SQLite 无法等价模拟 device-token upsert 语义。
- **测试环境隔离**——conftest 起独立 engine 连 `banban_test`，每用例事务回滚或 truncate；Redis 用 fakeredis 打桩（限流逻辑只依赖 incr/expire 接口）。
- **审查产出文档化**——报告写 `docs/security-review.md`，每项发现标注严重级别与修复任务号，修复不丢上下文。
- **CI 先后端后 iOS**——后端 job 跑 ruff + pytest（postgres/redis service 容器）；iOS job 只做 xcodebuild 构建验证（项目无 iOS 测试）。
- **trunk-based 不变**——CI 在 push main 时触发，失败即报告（无 PR 门禁机制，与现有工作流一致）。

## Task List

### Phase 1: 安全审查（只读，产出报告）
- [x] Task 1: 审查认证与限流域——auth.py/services/auth.py/sms.py/rate_limit.py/deps.py/JWT 生命周期/验证码爆破面/client_ip 伪造
- [x] Task 2: 审查敏感数据与外部面——verification(身份证/活体)/OSS 上传/WS handler(hub)/第三方适配器(wechat/apple/aliyun)/错误响应与日志泄露
- [x] Task 3: 汇总 `docs/security-review.md`（高/中/低分级 + 修复任务号），细化 Phase 2 修复任务

### Checkpoint 1
- [x] 审查报告完成，修复任务已细化，向用户汇报发现

### Phase 2: 安全修复（按 docs/security-review.md 细化）
- [x] Task 4: 修复高危 F1 + F2——`app_debug` 默认改 `False`；非 debug 且 secret_key 为默认值时启动 fail-fast；`.env.example` / `.env.development.example` 显式配 `APP_DEBUG=true`（开发场景；compose 经 env_file 透传无需改）
- [x] Task 5: 修复中低危 F3 + F6 + F16——`client_ip` 增加 `app_trusted_proxy_count`（默认 0 不信任 XFF，取倒数第 N 段）；sms 日志手机号打码；验证码改 `secrets.randbelow`。F4/F7/F12 记录为接受/待办，不改代码

### Checkpoint 2
- [x] 修复项全部关闭，curl 冒烟矩阵回归通过（sms send/verify/token/profile/fail-fast/打码/XFF 单测；uvicorn 默认 proxy_headers 行为分析确认各部署形态无绕过面）

### Phase 3: 测试补齐
- [x] Task 6: 测试基础设施——`uv sync --all-extras`、conftest.py（banban_test engine + fakeredis + app fixture）、CI 可复用的 pytest 配置
- [x] Task 7: auth 链路测试——sms send/verify、refresh 轮换、logout、device-token upsert/删除语义
- [x] Task 8: 限流测试——rate_limit 依赖窗口计数与 429、sms 自然日窗口
- [x] Task 9: chat/push/筛选测试——发消息未读累加、离线才推（hub.is_online 分支）、filter 生效
  - 附带修复：`_project_batch` 对无 profiles 行用户兜底缺失（会话/匹配列表 500，与 docstring 设计意图不符）

### Checkpoint 3
- [x] `pytest` 全绿（33 passed）；被测核心链路 ≥ 5 条（health、sms 登录注册、refresh/logout、device-token、chat 未读/已读、APNs 离线推送、filter）

### Phase 4: CI
- [x] Task 10: 后端 workflow——`.github/workflows/ci.yml` backend job（ruff + pytest + postgres/redis services；`BANBAN_TEST_DATABASE_URL` 指向 service 容器，建表走 create_all 无需 alembic）
- [x] Task 11: iOS workflow——同一文件 iOS job（xcodebuild 输出落日志文件，以含 ** BUILD SUCCEEDED ** 为准，不依赖 grep 管道退出码）

### Checkpoint 4
- [ ] push main 触发 CI 全绿（workflow 已就绪，待提交推送后在线上验证）

## Risks and Mitigations

| 风险 | 影响 | 缓解 |
|------|------|------|
| PG 方言特性使 SQLite 方案失效 | 测试无法跑 | 已决策用真 Postgres（banban_test）；CI 用 service 容器 |
| 安全修复改变 API 行为，前端回归 | 中 | 修复后跑现有 curl 冒烟矩阵；iOS 端如有行为变化同步修 |
| 本地 Redis/Postgres 状态残留致测试偶发失败 | 中 | conftest 每用例清理；测试库独立于开发库 |
| 审查发现高危需中断计划 | 低 | 高危立即修（优先于一切），修复本身计入 Phase 2 |

## Open Questions

- iOS 功能收尾（选图 UI、badge 清零、MockData 切服务端）不在本计划内，默认延后——如需并入请说。
