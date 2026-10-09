#  aliyun_sms.py
#  阿里云短信 adapter：生产走 SDK 真实发送，开发环境未配 AK 时降级为 mock（日志打印）

import json
import logging

from app.config import settings

logger = logging.getLogger("banban.sms")


class SmsSendError(Exception):
    """短信发送失败（第三方返回非 OK 或抛异常）"""


class DevMockSmsSender:
    """开发环境 mock：验证码打进日志，配合 APP_DEBUG 响应里的 debug_code 完成闭环"""

    async def send_code(self, phone: str, code: str) -> None:
        logger.info("[DEV MOCK] 短信验证码 phone=%s code=%s", phone, code)


class AliyunSmsSender:
    """阿里云短信（惰性初始化 client，避免无 AK 时启动报错）"""

    def __init__(self) -> None:
        self._client = None

    def _get_client(self):
        if self._client is None:
            # 延迟导入：mock 环境无需加载 SDK
            from alibabacloud_dysmsapi20170525 import models as sms_models
            from alibabacloud_dysmsapi20170525.client import Client as SmsClient
            from alibabacloud_tea_openapi import models as open_api_models

            config = open_api_models.Config(
                access_key_id=settings.aliyun_sms_access_key_id,
                access_key_secret=settings.aliyun_sms_access_key_secret,
                endpoint="dysmsapi.aliyuncs.com",
            )
            self._client = SmsClient(config)
            # 供 send_code 内构造请求用
            self._sms_models = sms_models
        return self._client

    async def send_code(self, phone: str, code: str) -> None:
        client = self._get_client()
        request = self._sms_models.SendSmsRequest(
            phone_numbers=phone,
            sign_name=settings.aliyun_sms_sign_name,
            template_code=settings.aliyun_sms_template_code,
            template_param=json.dumps({"code": code}),
        )
        response = await client.send_sms_async(request)
        body = response.body
        if body.code != "OK":
            logger.warning(
                "阿里云短信发送失败 phone=%s code=%s msg=%s", phone, body.code, body.message,
            )
            raise SmsSendError(body.message or "短信发送失败")


def build_sms_sender() -> DevMockSmsSender | AliyunSmsSender:
    """按配置选择 sender：配了 AK 用阿里云，否则（开发环境）用 mock"""
    if settings.aliyun_sms_access_key_id and settings.aliyun_sms_template_code:
        return AliyunSmsSender()
    logger.warning("未配置阿里云短信 AK，使用 DevMock sender（仅限开发环境）")
    return DevMockSmsSender()
