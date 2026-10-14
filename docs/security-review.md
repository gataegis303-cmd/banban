# BanBan 后端安全审查报告

> 审查日期：2026-10-13 · 范围：`backend/app` 全量 · 方法：信任边界分析 + STRIDE + OWASP Top 10 对照
> 结论：**1 项高危、2 项中危、5 项低危**（其中 3 项低危为接受/待办），核心鉴权与会话授权面无发现。

## 发现总表

| 编号 | 级别 | 摘要 | 位置 | 处置 |
|------|------|------|------|------|
| F1 | **高** | `app_debug` 默认 `True`：验证码泄露 + SQL echo 打 PII + 微信 dev 直通可接管任意账号 | [config.py](../backend/app/config.py#L16) | Task 4 修复 |
| F2 | 中 | `app_secret_key` 默认值无启动校验，生产漏配即 JWT 可伪造 | [config.py](../backend/app/config.py#L19) | Task 4 修复 |
| F3 | 中 | `client_ip` 无条件信任 X-Forwarded-For 首段，限流体系可被伪造头绕过 | [deps.py](../backend/app/deps.py#L37-42) | Task 5 修复 |
| F4 | 低 | refresh token 不轮换、无 reuse detection（30 天窗口） | [routers/auth.py](../backend/app/routers/auth.py#L143) | 接受（已文档化权衡） |
| F6 | 低 | 日志打手机号全号 PII | [sms.py](../backend/app/services/sms.py#L110) | Task 5 修复 |
| F7 | 低 | JWT 无 `aud` 校验 | [deps.py](../backend/app/deps.py) | 接受（单服务场景） |
| F12 | 低 | 身份证号无跨用户唯一性校验（一人多号风控点） | [models/user.py](../backend/app/models/user.py#L84-99) | 接受（风控待办，见详情） |
| F16 | 低 | 验证码用 `random.randint` 而非 `secrets`（随机性弱） | [sms.py](../backend/app/services/sms.py) | Task 5 修复 |

## 详情

### F1（高）app_debug 默认开启 → 三个连锁泄露面

`config.py` 中 `app_debug: bool = True` 为默认值，一旦生产部署漏配环境变量即全量生效：

1. **验证码泄露**：[routers/auth.py](../backend/app/routers/auth.py#L72-76) 在 debug 模式把短信验证码直接放进响应体（`debug_code`），配合 `/auth/sms/send` 等于免短信注册任意账号。
2. **SQL echo**：`echo=settings.app_debug` 会把含手机号等 PII 的 SQL 参数打进日志。
3. **微信 dev 直通（账号接管）**：[wechat_oauth.py](../backend/app/adapters/wechat_oauth.py#L31-37) 在 debug 且未配 secret 时，`code="dev:{unionid}"` 直接按 unionid 登录——**攻击者可构造任意 unionid 接管已有微信账号**。实名认证适配器同理降级为 mock。

**修复**（Task 4）：默认值改为 `False`（安全默认）；`.env.example` / `.env.development.example` / docker-compose 显式声明 `APP_DEBUG=true`（开发场景）。

### F2（中）app_secret_key 默认值无 fail-fast

`app_secret_key: str = "change-me-..."`——生产漏配时服务照常启动，攻击者可用公开的默认值伪造任意用户 JWT。与 F1 组合修复：非 debug 模式启动时校验 secret_key 必须已改，否则拒绝启动。

### F3（中）client_ip 无条件信任 XFF 首段

`deps.py` 的 `client_ip` 直接取 `X-Forwarded-For` 第一段。该头可由客户端任意伪造，导致 [rate_limit.py](../backend/app/services/rate_limit.py) 与短信 IP 上限**全部失效**（每次请求换一个假 IP 即可绕过）。

**修复**（Task 5）：新增配置 `app_trusted_proxy_count`（默认 0 = 不信任 XFF，直接用 socket 对端 IP）；Nginx 反代部署时设 1，取 XFF 倒数第 N 段（标准语义：最右为最近一跳代理写入的真实客户端 IP）。

**uvicorn 双层解析说明**：uvicorn 自身默认 `proxy_headers=True` + `forwarded_allow_ips="127.0.0.1,::1"`——仅当请求**来源 IP 为 loopback** 时才信任 XFF 并改写 `scope["client"]`。各部署形态验证：公网直连（源 IP 非 loopback）→ uvicorn 不改写，应用层 `trusted_proxy_count=0` 用 socket IP，伪造头无法绕过；Nginx 容器反代（回源非 loopback）→ uvicorn 不改写，应用层 `trusted_proxy_count=1` 读 XFF 尾段；Nginx loopback 回源 → uvicorn 改写为 nginx 追加后的尾段（真实客户端 IP）。本地 curl 看到伪造 ip=9.9.9.9 属 loopback 来源的开发便利行为，不构成风险。**无需改 uvicorn 启动参数，现有组合（uvicorn 默认 + 应用层 tpc）各形态均安全。**

### F4（低）refresh token 不轮换

refresh token 有效期内可反复使用，泄露后 30 天窗口内无法检测盗用。已在代码注释文档化为权衡（原型阶段）。后续可加「刷新即轮换 + 旧 token reuse 即全家族撤销」。

### F6（低）日志打手机号全号

`sms.py` 发送日志 `phone=%s` 打全号，违反最小化原则。修复：打码为 `138****1234`。

### F7（低）JWT 无 aud 校验

单服务自签自验场景下 `aud` 缺失可接受；未来拆分服务或引入第三方消费方时必须补。

### F12（低）身份证号无跨用户唯一性校验

`user_verifications` 表仅存打码证号（前 4 后 4）于 JSONB，无法在 DB 层查重——一人可用多个手机号完成多次实名（交友平台典型风控点）。修复需新增证号 SHA-256 哈希列 + 唯一索引，涉及表结构变更，**列为产品风控待办**，不在本轮质量债范围。

### F16（低）验证码随机源

`sms.py` 用 `random.randint` 生成 6 位验证码（Mersenne Twister 非密码安全）。改为 `secrets.randbelow`，一行改动。

## 已确认安全项（无发现）

| 面 | 验证内容 |
|------|------|
| Apple 登录 | [apple_auth.py](../backend/app/adapters/apple_auth.py)：RS256 强制、iss/aud 校验、JWKS 24h 缓存 + kid 未命中强刷、nonce sha256 对比——实现规范 |
| 会话授权 | [chat.py](../backend/app/services/chat.py) 全部操作走参与方校验，非参与方与不存在一律 404 不泄露存在性；seq 分配 FOR UPDATE 串行化 |
| WS 通道 | [ws/handler.py](../backend/app/ws/handler.py)：query param token 为浏览器 WS 限制下的合理权衡；content ≤2000、client_msg_id ≤64；close 4401 鉴权失败 |
| 照片上传 | [profile.py](../backend/app/routers/profile.py) + [oss.py](../backend/app/adapters/oss.py)：归属校验、content-type 白名单（Pydantic `Literal` 强校验）、10MB 上限、oss_key 全程服务端构造（uuid4 + 字典映射 ext），**无路径穿越面** |
| 设备令牌 | token 全局唯一改绑语义正确；注销接口凭 token 删除（token 即设备凭据），未知 token 同样 204 不泄露存在性 |
| CORS | 生产 `allow_origins=[]` + credentials 组合安全；debug 下 `*` 属于开发便利，随 F1 一并收敛 |
| 错误响应 | main.py 统一错误体不泄露内部细节 |
| 实名校验 | 身份证 GB 11643-1999 本地校验、未满 18 拒绝、入库证号打码、生产未接入抛 503 |

## 修复计划

| 任务 | 内容 | 改动点 |
|------|------|------|
| **Task 4** | F1 + F2：`app_debug` 默认 False；非 debug 时 secret_key 默认值 fail-fast；三个 env 模板/compose 显式配 `APP_DEBUG=true` | config.py、.env.example、.env.development.example、docker-compose.yml |
| **Task 5** | F3：`app_trusted_proxy_count`（默认 0）+ client_ip 改造；F6：手机号打码；F16：`secrets.randbelow` | deps.py、config.py、sms.py |
