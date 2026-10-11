#  verification.py
#  实名认证接口的请求/响应模型（Pydantic v2）

from pydantic import BaseModel, Field

# 身份证号格式约束在 schema 层做（系统边界）；校验码/出生日期/成年在 adapter 层校验
_ID_NUMBER = r"^\d{17}[\dXx]$"


class IDCardVerifyRequest(BaseModel):
    real_name: str = Field(min_length=2, max_length=30, description="身份证姓名")
    id_number: str = Field(pattern=_ID_NUMBER, description="18 位居民身份证号")


class VerificationResponse(BaseModel):
    verification: str
