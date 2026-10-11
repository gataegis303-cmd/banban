#  verification.py
#  实名认证服务：两要素核验 / 活体确认结果落库，推进 users.verification 状态机
#
#  状态机只升不降：微信/Apple 新用户无 phone_verified 中间态，
#  直接做身份证认证应从 pending 推进到 id_verified，而非卡在前置态。

from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters import aliyun_realperson
from app.models.user import (
    User,
    UserVerification,
    VerificationLevel,
    VerificationStepStatus,
    VerificationType,
)

# VerificationLevel 枚举定义顺序即状态机推进顺序（models/user.py）
_LEVEL_ORDER = {level: index for index, level in enumerate(VerificationLevel)}


class FaceBeforeIDError(Exception):
    """活体检测前置校验失败：需先通过身份证实名"""


def _advance(user: User, target: VerificationLevel) -> None:
    """状态推进取 max，保证只升不降"""
    user.verification = max(user.verification, target, key=_LEVEL_ORDER.get)


async def pass_id_card(db: AsyncSession, user: User, real_name: str, id_number: str) -> str:
    """身份证两要素核验通过：写 user_verifications 记录并推进状态机，返回新状态值"""
    if _LEVEL_ORDER[user.verification] >= _LEVEL_ORDER[VerificationLevel.id_verified]:
        return user.verification.value  # 幂等：已实名不重复核验
    result = await aliyun_realperson.verify_id2_meta(real_name, id_number)
    db.add(
        UserVerification(
            user_id=user.id,
            type=VerificationType.id_card,
            status=VerificationStepStatus.passed,
            result=result,
        )
    )
    _advance(user, VerificationLevel.id_verified)
    return user.verification.value


async def pass_face(db: AsyncSession, user: User) -> str:
    """活体检测通过：前置要求已通过身份证实名，写记录并推进状态机"""
    if _LEVEL_ORDER[user.verification] < _LEVEL_ORDER[VerificationLevel.id_verified]:
        raise FaceBeforeIDError
    result = await aliyun_realperson.confirm_face_verification(str(user.id))
    db.add(
        UserVerification(
            user_id=user.id,
            type=VerificationType.face,
            status=VerificationStepStatus.passed,
            result=result,
        )
    )
    _advance(user, VerificationLevel.face_verified)
    return user.verification.value
