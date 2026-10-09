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
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_secret_key: str = "change-me-to-a-64-char-random-string"

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
    apple_bundle_id: str = "com.banban.app"
    apple_team_id: str = ""
    apple_key_id: str = ""
    apple_private_key_path: str = ""

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
