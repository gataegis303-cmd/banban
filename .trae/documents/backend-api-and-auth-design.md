# BanBan 后端 API + 真实认证方案

## Context

BanBan iOS 原型已完成（v1.0.0），五轴代码审查全通过，但全部数据来自 `MockData.swift` 静态枚举，无后端/无网络/无持久化。本方案设计后端 API 层 + 真实认证，使 iOS 端从 Mock 切换到真实后端，为上线生产做准备。

**技术栈**：Python + FastAPI / PostgreSQL / Redis / WebSocket 自建 / 阿里云短信 / 微信 OAuth / Apple Sign-In

## 架构总览

```
iOS App ──HTTPS/WSS──▶ Nginx (TLS+WSS) ──▶ FastAPI ──▶ PostgreSQL
                                              ├──▶ Redis (验证码/在线态/限流)
                                              ├──▶ OSS (照片)
                                              └──▶ 第三方 (阿里云短信/实人认证/微信OAuth/AppleJWT)
```

**核心原则**：
- 后端单真源：规范化富资料（对齐 `MyProfile` 全字段），`UserProfile` 为投影序列化结果
- iOS 引入 Repository 层，AppState 从 MockData 切换为 async Repository 调用
- 服务端权威：消息 ID/时间戳、匹配判定、年龄（由 birthday 派生）

## 数据库 Schema（关键表）

### users（认证身份层）
- `id UUID PK`, `phone VARCHAR(20) UNIQUE`, `wechat_unionid VARCHAR(64) UNIQUE`, `apple_sub VARCHAR(64) UNIQUE`
- `verification ENUM(pending|phone_verified|id_verified|face_verified|complete)`
- `age SMALLINT GENERATED ALWAYS AS (GREATEST(18, EXTRACT(YEAR FROM age(birthday))::INT)) STORED`

### profiles（富资料，对齐 MyProfile 全字段，与 users 1:1）
- 城市意向/职业/身高体重/教育/收入/婚姻/子女/居住/交通(transportNone/transportTools/transportCounts/taxiMonthlyQuota)/住房(housingSituation/spareRooms/housingConditions)/生活方式(smoking/drinking/sleep/pets)/匹配偏好(direction/partnerStatus/seeking/livingMode/financeTrial/financeFormal/childIntent/socialBoundary/parentRelation)/标签(noAccept/resources/otherTags)/aboutMe/headline

### user_photos（上限 6，sort_order 0-5）
### user_filters（筛选条件，对齐 FilterState）
### recommendations（推荐流水：user_id/target_id/batch_date/score/status）
### likes（liker_id/likee_id/direction=like|skip|block，UNIQUE(liker_id,likee_id)）
### matches（双向 like 触发，CHECK user_a_id < user_b_id）
### conversations（1 match 1 conversation，双方独立未读计数）
### messages（public_id UUID 对外暴露，seq 递增，type=text|system|image）
### refresh_tokens / user_presence / user_verifications / reports

## API 端点（前缀 `/api/v1`）

### 认证
| Method | Path | 说明 |
|--------|------|------|
| POST | `/auth/sms/send` | 发送验证码（Redis 存码+限流：60s间隔/日上限10/IP上限20） |
| POST | `/auth/sms/verify` | 验证码校验→登录/注册→签发 JWT(access 15min + refresh 30d) |
| POST | `/auth/wechat/login` | 微信 code→unionid→查/建用户 |
| POST | `/auth/apple/login` | Apple identity_token JWT 校验→sub→查/建用户 |
| POST | `/auth/refresh` | refresh_token 换新 access |
| POST | `/auth/logout` | 撤销 refresh |
| POST | `/verification/id-card` | 身份证 OCR+比对（阿里云实人认证） |
| POST | `/verification/face` | 活体检测 |

### 资料
- `GET/PUT /me/profile`（PUT 用增量合并语义对齐 `MyProfile.merge`：非空才覆盖）
- `POST /me/profile/submit`（注册向导完成）
- `POST /me/photos`（返回 OSS 预签名 URL）/ `DELETE /me/photos/{order}` / `PUT /me/photos/reorder`
- `GET/PUT /me/filter`

### 推荐/匹配
- `GET /recommendations?limit=10`（返回 UserProfile 投影 + distance + score）
- `POST /recommendations/{target_id}/like`（响应 `{matched: bool, match_id?}`）
- `POST /recommendations/{target_id}/skip` / `block`
- `GET /matches?cursor=&limit=` / `GET /matches/{id}`

### 会话/消息
- `GET /conversations`（含 last_message/unread/has_unread_dot）
- `GET /conversations/{id}/messages?cursor=&limit=20`（游标分页）
- `POST /conversations/{id}/messages`（HTTP 兜底，WS 为主通道）
- `POST /conversations/{id}/read` / `DELETE /conversations/{id}`（unmatch）

### UserProfile 投影（后端 projection_service 拼接 cardTags/intentionTags）
iOS `UserProfile` 模型零改动——后端按 MockData 的拼接规则生成标签数组。

### ChatMessage 扩展（最小侵入）
- `id` 从 `UUID()` 改 `let id: String`（服务端 public_id）
- 新增 `timestamp: Date` / `seq: Int64`
- `isMe` 保留，由 DTO 映射填充

## WebSocket 协议

连接：`wss://api.banban.app/ws/chat?token={access_token}`

| type | 方向 | 说明 |
|------|------|------|
| `hello` | S→C | 连接确认 |
| `message` | C→S | 发送消息（含 client_msg_id 乐观更新） |
| `message` | S→C | 新消息广播（含自己回执） |
| `ack` | S→C | 发送回执（替换临时 id 为服务端 id） |
| `typing` | 双向 | 正在输入 |
| `read` | 双向 | 已读同步 |
| `online_status` | S→C | 对方上下线 |
| `match` | S→C | 新匹配通知 |
| `ping/pong` | 双向 | 30s 心跳 |

离线同步：客户端持久化 `last_seq` per conversation；重连后 HTTP `GET /messages?since_seq=42` 增量拉取；离线走 APNs 推送。

## iOS 端集成

### 新建文件
```
ios/BanBan/Networking/
├── APIClient.swift          # async/await URLSession，401 自动 refresh+重放
├── APIError.swift           # 统一错误模型
├── Endpoint.swift           # 路径/方法/Header
├── KeychainTokenStore.swift # kSecAttrAccessible=.afterFirstUnlockThisDeviceOnly
├── AuthInterceptor.swift    # Bearer 注入 + 401 重试
└── WebSocketClient.swift    # URLSessionWebSocketTask，自动重连

ios/BanBan/Repositories/
├── AuthRepository.swift     # sendSMS/verify/wechat/apple/refresh/logout
├── UserRepository.swift     # getProfile/updateProfile/submitProfile/uploadPhoto
├── MatchRepository.swift    # recommendations/like/skip/matches
├── ChatRepository.swift     # conversations/messages(分页)/sendHTTP/read
├── FilterRepository.swift   # getFilter/updateFilter
└── PresenceRepository.swift # online status

ios/BanBan/Models/DTOs.swift  # 服务端 JSON Codable 映射
```

### AppState 改造
- 注入 6 个 Repository（BanBanApp 装配）
- `myProfile` 改 Optional（未登录 nil）
- `recommendations`/`conversations` 初始空数组，bootstrap() 异步拉取
- 启动读 Keychain：有 token → `phase=.main` + bootstrap()；无 → `.onboarding`
- `likeCurrent()` → `Task { let res = try await matches.like(targetID); if res.matched { matchUser = user } }`
- `send(to:text:)` → 乐观插入临时消息 → WS 发 → 收 ack 替换 id
- 新增 `isLoading`/`error` 状态
- `logout()` → 清 Keychain + 回 onboarding

### 调用点改造
- **LoginView**：「获取验证码」→ `auth.sendSMS(phone)` + 验证码输入页
- **VerifyIDView**：步骤2/3 → `auth.verifyIDCard()`/`auth.verifyFace()`
- **PermissionsView**：真实 `CLLocationManager`/`UNUserNotificationCenter`/`PHPhotoLibrary`
- **WizardFlowView**：`completeRegistration()` → `await users.submitProfile(draft)`
- **HomeView**：`onAppear → await appState.refreshRecommendations()`
- **ChatView**：`onAppear → await chats.loadMessages() + WS 连接`
- **SettingsView**：退出登录 → `await appState.logout()`

## 后端项目结构

```
backend/
├── app/
│   ├── main.py / config.py / deps.py
│   ├── routers/ (auth, verification, profile, recommendations, matches, conversations, messages, filters, ws)
│   ├── models/ (SQLAlchemy 2.0 async)
│   ├── schemas/ (Pydantic v2，含 projections.py)
│   ├── services/ (auth, sms, wechat, apple, verification, matching, projection, presence)
│   ├── ws/ (hub.py, events.py, handler.py)
│   ├── middleware/ (rate_limit, request_id, error_handler)
│   └── adapters/ (aliyun_sms, aliyun_realperson, wechat_oauth, oss)
├── alembic/
├── tests/
├── docker-compose.yml (db+redis+api+nginx)
├── Dockerfile / .env.example / nginx/banban.conf
└── pyproject.toml (uv)
```

## 实现步骤排序

| P | 步骤 | 依赖 | 验收 |
|---|------|------|------|
| P0 | 后端骨架：FastAPI+PG+Redis+Alembic 首版迁移 | 无 | health 200，迁移成功 |
| P1 | 短信发送/验证 + JWT 签发/刷新 | P0 | Postman 走通 send→verify→refresh |
| P2 | iOS APIClient+Keychain+AuthRepository+LoginView 接入 | P1 | 真机收到验证码并登录拿 token |
| P3 | 资料 CRUD + 投影层 + 照片上传 | P0 | 注册向导能提交并回读 |
| P4 | iOS UserRepository + WizardFlow/MyProfileView 接入 | P3 | 真机完成注册→主流程 |
| P5 | 推荐 + like/skip + 双向匹配检测 | P3 | like 后对方也 like 则生成 match |
| P6 | iOS MatchRepository + HomeView 接入 | P5 | 真机推荐来自后端 |
| P7 | 会话/消息 HTTP 接口 | P5 | curl 能发消息拉历史 |
| P8 | WebSocket Hub + 事件协议 + 在线态 | P7 | 双端实时收发 |
| P9 | iOS WebSocketClient + ChatView/MessagesView 接入 | P7,P8 | 真机实时聊天 |
| P10 | 微信登录 + Apple Sign-In | P1 | 两端登录可用 |
| P11 | 实名认证对接第三方 | P1 | VerifyIDView 三步真实生效 |
| P12 | 筛选持久化 + 推荐按筛选过滤 | P5,P6 | FilterView 应用后推荐变化 |
| P13 | APNs 离线推送 + 限流加固 + 部署 | P8 | 离线收推送 |

## 关键文件

- [Models.swift](file:///Users/mia.369/Documents/Trae/Love/BanBan/ios/BanBan/Models/Models.swift) — ProfileDraft/MyProfile/UserProfile/ChatMessage/Conversation/FilterState 真实字段，DTO 对齐基准
- [Enums.swift](file:///Users/mia.369/Documents/Trae/Love/BanBan/ios/BanBan/Models/Enums.swift) — 枚举 rawValue，PG enum 与标签拼接规则来源
- [AppState.swift](file:///Users/mia.369/Documents/Trae/Love/BanBan/ios/BanBan/Support/AppState.swift) — Repository 注入与 bootstrap/logout/likeCurrent/send 改造主战场
- [MockData.swift](file:///Users/mia.369/Documents/Trae/Love/BanBan/ios/BanBan/Support/MockData.swift) — UserProfile 投影规则参考实现
- [VerifyIDView.swift](file:///Users/mia.369/Documents/Trae/Love/BanBan/ios/BanBan/Views/Auth/VerifyIDView.swift) — 实名三步流对齐基准

## Verification

- P0-P1: `alembic upgrade head` 成功 + health 200 + Postman 走通认证流
- P2: 真机收到短信验证码并登录拿到 JWT token
- P3-P4: 真机完成注册向导→主流程，资料来自后端
- P5-P6: 真机推荐卡片来自后端，like 后匹配检测正确
- P7-P9: 真机实时聊天（WS 主通道 + HTTP 兜底）
- P10-P13: 微信/Apple 登录、实名认证、APNs 推送、生产部署

## 前置风险

- **Apple Sign-In**：App Store 审核 4.8 强制要求（有第三方登录必提供），P10 必须完成
- **实名认证资质**：阿里云实人认证需企业资质，P11 可能阻塞上架，提前申请
- **WebSocket 稳定性**：NAT 下长连接需测弱网重连
