# ADR-002: Mock 数据策略（无后端原型）

## Status
Accepted

## Date
2026-10-01

## Context

BanBan 原型需要完整还原 18 页交互流（引导 → 注册 → 主流程 → 消息 → 资料），但无后端 API 可用。需要决定数据来源策略。

## Decision

使用 `MockData.swift` 静态枚举提供全量数据：

- 推荐用户列表（5 条 UserProfile）
- 会话与消息记录（3 条带消息历史）
- 当前用户头像 URL
- `filterResultCount(_:)` 用筛选条件哈希派生 3~28 的稳定伪随机值

`AppState` 初始化时从 `MockData` 加载，运行时所有状态变更都在内存中完成（like/skip/advanceCard/send 等）。

## Alternatives Considered

### JSON 文件 + Codable 解析
- Pros: 数据与代码分离，可替换为真实 API 响应
- Cons: 增加解析层复杂度，原型阶段数据结构频繁变动
- Rejected: Swift 枚举直接构造更直观，且类型安全

### mock server（如 Mockoon / WireMock）
- Pros: 还原真实网络请求流程
- Cons: 需要额外运行 mock server，增加开发环境复杂度
- Rejected: 原型阶段关注 UI/交互验证，网络层后续统一引入

## Consequences

- 无网络请求 / 无数据持久化，退出后状态不保留
- `AppState.logout()` 重置回 `MockData.conversations` 初始值
- 迁移到真实后端时需要：引入 Repository 层、将 MockData 替换为 API 调用、处理异步加载与错误状态
- `filterResultCount` 是演示用伪随机，真实场景需替换为后端搜索接口
