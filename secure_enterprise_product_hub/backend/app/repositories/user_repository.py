from bson import ObjectId
from pymongo.errors import DuplicateKeyError

from app.core.database import db


class UserRepository:
    async def create(self, user: dict) -> str:
        try:
            result = await db.users.insert_one(user)
        except DuplicateKeyError as exc:
            raise ValueError("Email already exists") from exc
        return str(result.inserted_id)

    async def find_by_email(self, email: str) -> dict | None:
        return await db.users.find_one({"email": email.lower()})

    async def find_by_id(self, user_id: ObjectId) -> dict | None:
        return await db.users.find_one({"_id": user_id})
