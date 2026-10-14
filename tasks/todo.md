# 质量债偿还（安全审查 → 测试 → CI）

计划详情见 [plan.md](./plan.md)。

## Phase 1: 安全审查
- [x] Task 1: 审查认证与限流域（auth/sms/rate_limit/deps/JWT）
- [x] Task 2: 审查敏感数据与外部面（verification/OSS/WS/第三方适配器/日志泄露）
- [x] Task 3: 汇总 docs/security-review.md + 细化修复任务

## Phase 2: 安全修复
- [x] Task 4: 修复高危 F1+F2（app_debug 默认 False + secret_key fail-fast + env 模板显式 APP_DEBUG）
- [x] Task 5: 修复中低危 F3+F6+F16（trusted_proxy_count + 手机号打码 + secrets.randbelow）

## Phase 3: 测试补齐
- [x] Task 6: 测试基础设施（conftest.py：banban_test engine + fakeredis + app fixture）
- [x] Task 7: auth 链路测试
- [x] Task 8: 限流测试
- [x] Task 9: chat/push/筛选测试

## Phase 4: CI
- [x] Task 10: 后端 workflow（ruff + pytest + services）
- [x] Task 11: iOS workflow（xcodebuild）

## Checkpoints
- [x] CP1: 审查报告完成并汇报
- [x] CP2: 修复关闭 + curl 冒烟回归
- [x] CP3: pytest 全绿
- [ ] CP4: CI 全绿（待 push 验证）
