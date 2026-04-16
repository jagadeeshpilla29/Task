from fastapi import APIRouter, Depends, status

from app.api.dependencies import current_user
from app.schemas.auth import LoginRequest, RegisterRequest
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])
auth_service = AuthService()


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest) -> dict:
    return await auth_service.register(payload)


@router.post("/login")
async def login(payload: LoginRequest) -> dict:
    return await auth_service.login(payload)


@router.get("/me")
async def me(user: dict = Depends(current_user)) -> dict:
    return auth_service.profile(user)


@router.post("/logout")
async def logout(_: dict = Depends(current_user)) -> dict:
    return auth_service.logout()
