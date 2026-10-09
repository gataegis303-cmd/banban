#  models/__init__.py
#  汇总导出全部模型，供 Alembic autogenerate 通过 Base.metadata 发现

from app.models.base import Base
from app.models.chat import Conversation, Message, Report
from app.models.matching import Like, Match, Recommendation
from app.models.profile import Profile, UserFilter, UserPhoto
from app.models.user import RefreshToken, User, UserPresence, UserVerification

__all__ = [
    "Base",
    "Conversation",
    "Like",
    "Match",
    "Message",
    "Profile",
    "Recommendation",
    "RefreshToken",
    "Report",
    "User",
    "UserFilter",
    "UserPhoto",
    "UserPresence",
    "UserVerification",
]
