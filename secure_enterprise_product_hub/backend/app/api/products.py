from fastapi import APIRouter, Depends, File, Query, UploadFile, status

from app.api.dependencies import current_user, require_admin
from app.schemas.product import ProductCreate, ProductUpdate
from app.services.product_service import ProductService

router = APIRouter(prefix="/products", tags=["products"])
product_service = ProductService()


@router.get("")
async def list_products(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=10, ge=1, le=50),
    search: str | None = Query(default=None),
    category: str | None = Query(default=None),
    _: dict = Depends(current_user),
) -> dict:
    return await product_service.list_products(page, limit, search, category)


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_product(payload: ProductCreate, user: dict = Depends(require_admin)) -> dict:
    return await product_service.create_product(payload, user)


@router.get("/{product_id}")
async def get_product(product_id: str, _: dict = Depends(current_user)) -> dict:
    return await product_service.get_product(product_id)


@router.put("/{product_id}")
async def update_product(product_id: str, payload: ProductUpdate, _: dict = Depends(require_admin)) -> dict:
    return await product_service.update_product(product_id, payload)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(product_id: str, _: dict = Depends(require_admin)) -> None:
    await product_service.delete_product(product_id)


@router.post("/{product_id}/image")
async def upload_image(
    product_id: str,
    image: UploadFile = File(...),
    _: dict = Depends(require_admin),
) -> dict:
    return await product_service.upload_image(product_id, image)
