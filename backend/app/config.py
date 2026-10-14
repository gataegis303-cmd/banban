#  config.py
#  全局配置（pydantic-settings，环境变量注入）

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        case_insensitive=True,
        extra="ignore",
    )

    # 应用
    app_env: str = "development"
    # 安全默认 False：debug 开启会泄露验证码响应体 / SQL echo PII / 微信与实名 dev 降级，
    # 开发环境须在 .env 显式声明 APP_DEBUG=true
    app_debug: bool = False
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_secret_key: str = "change-me-to-a-64-char-random-string"
    # 反向代理链上可信代理的层数（0 = 不信任 X-Forwarded-For，按 socket 直连 IP 计）
    # Nginx 单层反代设 1：取 XFF 倒数第 1 段（最近一跳代理写入的真实客户端 IP），
    # 防止客户端伪造 XFF 头绕过 IP 限流（审查 F3）
    app_trusted_proxy_count: int = 0

    # 数据库
    database_url: str = (
        "postgresql+asyncpg://banban:banban_dev_2025@postgres:5432/banban"
    )

    # Redis
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: str = ""

    # JWT
    jwt_access_expire_minutes: int = 15
    jwt_refresh_expire_days: int = 30
    jwt_algorithm: str = "HS256"

    # 短信验证码（限流与有效期）
    sms_code_ttl_seconds: int = 300        # 验证码有效期 5 分钟
    sms_send_cooldown_seconds: int = 60    # 同手机号重发间隔
    sms_daily_limit: int = 10              # 同手机号每日上限
    sms_ip_daily_limit: int = 20           # 同 IP 每日上限
    sms_code_max_attempts: int = 5         # 单个验证码最大尝试次数

    # 通用 IP 限流（固定窗口，按端点 scope 区分；单位：次/分钟）
    rate_limit_verify_per_minute: int = 10    # /auth/sms/verify（防验证码爆破）
    rate_limit_refresh_per_minute: int = 30   # /auth/refresh
    rate_limit_oauth_per_minute: int = 10     # /auth/wechat/login、/auth/apple/login

    # 阿里云短信
    aliyun_sms_access_key_id: str = ""
    aliyun_sms_access_key_secret: str = ""
    aliyun_sms_sign_name: str = "斑斑"
    aliyun_sms_template_code: str = ""
    aliyun_sms_region: str = "cn-hangzhou"

    # 阿里云实人认证
    aliyun_realperson_access_key_id: str = ""
    aliyun_realperson_access_key_secret: str = ""

    # 微信 OAuth
    wechat_app_id: str = ""
    wechat_app_secret: str = ""

    # Apple Sign-In
    apple_bundle_id: str = "com.mia369.banban"
    apple_team_id: str = ""
    apple_key_id: str = ""
    apple_private_key_path: str = ""
    # identity_token 公钥来源；默认 Apple 官方，联调/测试可指向本地 mock JWKS
    apple_jwks_url: str = "https://appleid.apple.com/auth/keys"

    # APNs 离线推送（team/key 未配置时降级 DevMock，推送内容打日志）
    apns_team_id: str = ""
    apns_key_id: str = ""
    apns_private_key_path: str = ""
    apns_use_sandbox: bool = True  # True 走 sandbox（api.sandbox.push.apple.com）

    # OSS
    oss_access_key_id: str = ""
    oss_access_key_secret: str = ""
    oss_bucket_name: str = "banban-prod"
    oss_endpoint: str = "oss-cn-hangzhou.aliyuncs.com"
    oss_cdn_domain: str = ""

    @property
    def redis_url(self) -> str:
        auth = f":{self.redis_password}@" if self.redis_password else ""
        return f"redis://{auth}{self.redis_host}:{self.redis_port}/{self.redis_db}"


settings = Settings()

# 安全 fail-fast：非 debug（生产）模式禁止默认 secret_key，防 JWT 伪造（审查 F2）
if not settings.app_debug and settings.app_secret_key == "change-me-to-a-64-char-random-string":
    raise RuntimeError(
        "APP_SECRET_KEY 未配置：非 debug 模式禁止使用默认值，"
        "请在 .env 中设置随机密钥（或开发环境显式声明 APP_DEBUG=true）"
    )
