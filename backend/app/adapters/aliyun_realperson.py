#  aliyun_realperson.py
#  阿里云实人认证适配器：身份证两要素核验（Id2MetaVerify）+ 活体检测结果确认
#
#  开发降级：未配置 AK 且 APP_DEBUG=true 时，两要素走本地校验码算法（GB 11643-1999）、
#  活体直通，供无企业资质阶段的闭环验收。生产接入需企业资质开通实人认证服务。

import logging
from datetime import date

from app.config import settings

logger = logging.getLogger("banban.realperson")


class RealPersonError(Exception):
    """实名核验失败；status_code 供路由层映射 HTTP 状态"""

    def __init__(self, message: str, status_code: int = 422):
        super().__init__(message)
        self.status_code = status_code


# GB 11643-1999 校验码：加权因子与校验码表
_ID_WEIGHTS = (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2)
_ID_CHECK_CODES = "10X98765432"


def _check_id_number(id_number: str) -> None:
    """18 位身份证本地校验：出生日期合法性 + 校验码；未满 18 周岁拒绝"""
    try:
        birth = date.fromisoformat(
            f"{id_number[6:10]}-{id_number[10:12]}-{id_number[12:14]}"
        )
    except ValueError as exc:
        raise RealPersonError("身份证号出生日期不正确") from exc
    today = date.today()
    age = today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))
    if age < 18:
        raise RealPersonError("未满 18 周岁，无法完成实名认证")
    checksum = sum(int(d) * w for d, w in zip(id_number[:17], _ID_WEIGHTS, strict=True))
    if _ID_CHECK_CODES[checksum % 11] != id_number[17].upper():
        raise RealPersonError("身份证号校验位不正确")


def _mask_id_number(id_number: str) -> str:
    """证号脱敏后入库（result JSONB）：前 4 后 4，中间打码"""
    return f"{id_number[:4]}**********{id_number[-4:]}"


async def verify_id2_meta(real_name: str, id_number: str) -> dict:
    """身份证二要素核验（姓名 + 证号），返回写入 user_verifications.result 的凭据"""
    if not settings.aliyun_realperson_access_key_id:
        if not settings.app_debug:
            raise RealPersonError("实名认证服务未配置", status_code=503)
        _check_id_number(id_number)
        logger.info(
            "[DEV MOCK] 身份证两要素核验 real_name=%s id_number=%s",
            real_name, _mask_id_number(id_number),
        )
        return {
            "provider": "dev_mock",
            "real_name": real_name,
            "id_number": _mask_id_number(id_number),
        }

    # 生产接入点：阿里云实人认证 Id2MetaVerify（身份证二要素核验）。
    # 需企业资质开通服务并安装 SDK（alibabacloud_cloudauth20190319）后补全调用：
    # client.id2_meta_verify(Id2MetaVerifyRequest(RealName=..., IdCard=..., SceneCode=...))，
    # 响应 ResponseCode == "0000" 视为核验一致，否则按错误码转译 RealPersonError。
    raise RealPersonError("实名认证服务未接入（等待企业资质开通）", status_code=503)


async def confirm_face_verification(user_id: str) -> dict:
    """活体检测结果确认，返回写入 user_verifications.result 的凭据。

    完整方案需 App 端接入金融级实人认证 SDK（企业资质）：
    GetVerifyToken 下发 certifyId → 端上 SDK 认证 → DescribeVerifyResult 确认结果。
    """
    if not settings.aliyun_realperson_access_key_id:
        if not settings.app_debug:
            raise RealPersonError("活体认证服务未配置", status_code=503)
        logger.info("[DEV MOCK] 活体检测直通 user_id=%s", user_id)
        return {"provider": "dev_mock"}

    # 生产接入点：凭端上 SDK 认证回执的 certifyId 调 DescribeVerifyResult，
    # VerificationStatus == "PASSED" 视为通过。
    raise RealPersonError("活体认证服务未接入（等待企业资质开通）", status_code=503)
