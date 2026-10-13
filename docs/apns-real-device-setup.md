# APNs 真机联调配置步骤

> 适用范围：BanBan iOS 真机收到离线推送横幅的完整链路配置。
> 前置：P13 已完成（device_tokens 表、PUT/DELETE /me/device-token、推送触发点、DevMock 降级）。

## 链路总览

```
真机 App 登录
  → NotificationManager 请求授权 + registerForRemoteNotifications
  → AppDelegate 收到 deviceToken → hex 上报 PUT /me/device-token
  → device_tokens 表落库

对方发消息（WS 或 HTTP）
  → push.push_new_message：接收方 Hub 离线？
  → 查接收方全部 DeviceToken → RealAPNS（JWT ES256 认证）
  → APNs sandbox → 真机收横幅（badge = 会话未读数）
```

## 一、Apple Developer 后台（一次性，约 10 分钟）

1. **确认 App ID 开启推送**：[developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) → Identifiers → 选 `com.mia369.banban` → 勾选 **Push Notifications**（若列表没有，先在 Xcode 真机 Run 一次让它自动创建，再回来勾选）
2. **创建 APNs Auth Key**：Identifiers → **Keys** → `+` → 名称随意（如 `banban-apns`）→ 勾选 **Apple Push Notifications service (APNs)** → Register → 下载 `AuthKey_<KEYID>.p8`（**只能下载一次**，丢失只能 Revoke 重建）
3. 记下两个值：
   - **Key ID**：下载页显示的 10 位字符
   - **Team ID**：右上角账户 → Membership details 里的 10 位字符

## 二、Xcode 工程（真机能力）

1. 打开 `ios/BanBan.xcodeproj` → Target BanBan → **Signing & Capabilities**
2. `+ Capability` → 添加 **Push Notifications**
3. 确认：Team 已选、Bundle ID `com.mia369.banban`、Automatically manage signing 勾选

## 三、真机访问后端的两个必改项

真机上 `127.0.0.1` 指向手机自己，且明文 HTTP 默认被 ATS 阻断——这两点只上真机才暴露。

1. **baseURL 改局域网 IP**：
   - 查 Mac IP：系统设置 → Wi-Fi → 详细信息，形如 `192.168.x.x`
   - 改 `ios/BanBan/Networking/APIClient.swift`：
     ```swift
     static let defaultBaseURL = URL(string: "http://192.168.x.x:8000/api/v1")!
     ```
   - uvicorn 已监听 `0.0.0.0`，无需改后端
2. **ATS 例外**：Target BanBan → **Info** tab → 添加 `App Transport Security Settings` → 子键 `Allows Local Networking` = `YES`
   （Xcode 会自动创建 Info.plist 并与生成键合并，不破坏现有 INFOPLIST_KEY 设置）

## 四、后端 .env 配置

编辑 `backend/.env`（本地开发版模板见对话/`.env.example` 的本地差异说明），追加或补全：

```bash
# .p8 私钥复制到 backend/secrets/（.gitignore 已忽略 *.p8，不会入库）
APNS_TEAM_ID=你的TeamID
APNS_KEY_ID=你的KeyID
APNS_PRIVATE_KEY_PATH=secrets/AuthKey_XXXXXXXXXX.p8
APNS_USE_SANDBOX=true   # Xcode 真机直跑 = development 证书 = sandbox，保持 true
```

重启并确认：

```bash
cd backend && pkill -f "uvicorn app.main:app" ; sleep 1
APPLE_JWKS_URL=http://127.0.0.1:8081/jwks.json nohup .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 > /tmp/banban-uvicorn.log 2>&1 & sleep 3
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/docs   # 预期 200
```

**启动判定**：

| 日志现象 | 含义 |
|---|---|
| 启动无任何 APNs 输出 | 正常（懒加载，首次推送才初始化） |
| `error` 级 APNs 日志 | .p8 路径/格式错误，回头查 .env |
| 推送时出现 `[APNs DevMock]` | 配置没生效（三项有一项为空） |

## 五、真机验证链路

1. iPhone 连 Mac，Xcode 真机 Run；登录账号 A → 弹通知授权 → **允许**
2. 验证 token 已上报（首次推送前 APNs 无日志，直接查库最准）：
   ```bash
   docker exec backend-postgres-1 psql -U banban -c \
     "SELECT user_id, left(token,16) AS token_head, platform FROM device_tokens ORDER BY updated_at DESC LIMIT 5;"
   ```
   出现 64 位 hex 真实 token（非 `a1b2c3...` 测试假值）即上报成功
3. 账号 A 退到后台（或杀掉 app）→ 另一账号 B（真机/模拟器均可）给 A 发消息
4. **预期**：A 收到横幅，title = 发送者 Profile.nickname，body = 消息内容（截断 100 字），badge = 该会话未读数；uvicorn 日志无 DevMock 字样、无 `APNSError`

## 常见坑

- **在线不推是设计行为**：接收方 app 在前台时走 WS 实时通道，服务端 `hub.is_online()` 判在线即跳过 APNs——测试推送时接收方必须退后台
- **sandbox / production**：`APNS_USE_SANDBOX=true` 对应 Xcode 开发直跑；TestFlight / App Store 分发要改 `false`（production host）
- **badge 不自动清零**：badge 由后端推送携带，读消息后本地未调 `setBadgeNumber(0)`，下次推送覆盖——已知小 gap，需要再补
- **授权拒绝**：token 仍会注册上报（静默推送可达），但 alert 横幅不显示；联调务必选允许
- **.p8 丢失**：只能 Revoke 重建 Key（换新 Key ID），.env 的 `APNS_KEY_ID` 同步更新
- **换 Wi-Fi / IP 变了**：baseURL 是硬编码 IP，IP 变了要同步改 APIClient.swift
