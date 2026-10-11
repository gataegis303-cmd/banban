#  verification.py
#  实名认证路由：身份证两要素核验 + 活体检测（CurrentUser 鉴权）

from fastapi import APIRouter, HTTPException, status

from app.adapters.aliyun_realperson import RealPersonError
from app.deps import CurrentUser, DBSession
from app.schemas.verification import IDCardVerifyRequest, VerificationResponse
from app.services import verification as verification_service
from app.services.verification import FaceBeforeIDError

router = APIRouter(prefix="/verification", tags=["verification"])


@router.post("/id-card", response_model=VerificationResponse)
async def verify_id_card(
    body: IDCardVerifyRequest, user: CurrentUser, db: DBSession
) -> VerificationResponse:
    try:
        level = await verification_service.pass_id_card(
            db, user, body.real_name, body.id_number
        )
    except RealPersonError as exc:
        raise HTTPException(
            exc.status_code, {"code": "verify_failed", "message": str(exc)}
        ) from None
    await db.commit()
    return VerificationResponse(verification=level)


@router.post("/face", response_model=VerificationResponse)
async def verify_face(user: CurrentUser, db: DBSession) -> VerificationResponse:
    try:
        level = await verification_service.pass_face(db, user)
    except FaceBeforeIDError:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            {"code": "face_before_id", "message": "请先完成身份证实名认证"},
        ) from None
    except RealPersonError as exc:
        raise HTTPException(
            exc.status_code, {"code": "verify_failed", "message": str(exc)}
        ) from None
    await db.commit()
    return VerificationResponse(verification=level)
