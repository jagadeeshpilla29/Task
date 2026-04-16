from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.core.security import create_access_token, hash_password, verify_password
from app.models.common import serialize_id
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest


class AuthService:
    def __init__(self, user_repository: UserRepository | None = None) -> None:
        self.user_repository = user_repository or UserRepository()

    async def register(self, payload: RegisterRequest) -> dict:
        now = datetime.now(timezone.utc)
        user = {
            "name": payload.name.strip(),
            "email": payload.email.lower(),
            "passwordHash": hash_password(payload.password),
            "role": payload.role,
            "createdAt": now,
            "updatedAt": now,
        }
        try:
            await self.user_repository.create(user)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

        return {"success": True, "message": "User registered successfully"}

    async def login(self, payload: LoginRequest) -> dict:
        user = await self.user_repository.find_by_email(payload.email)
        if user is None or not verify_password(payload.password, user["passwordHash"]):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

        token, expires_in = create_access_token(str(user["_id"]), user["role"])
        return {"success": True, "data": {"accessToken": token, "expiresIn": expires_in}}

    def profile(self, user: dict) -> dict:
        clean_user = user if "id" in user else serialize_id(user)
        return {
            "success": True,
            "data": {
                "id": clean_user["id"],
                "name": clean_user["name"],
                "email": clean_user["email"],
                "role": clean_user["role"],
            },
        }

    def logout(self) -> dict:
        return {"success": True, "message": "Logout successful"}
