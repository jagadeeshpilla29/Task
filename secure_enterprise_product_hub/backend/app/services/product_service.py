import re
from datetime import datetime, timezone

from fastapi import HTTPException, UploadFile, status

from app.models.common import object_id, serialize_id
from app.repositories.product_repository import ProductRepository
from app.schemas.product import ProductCreate, ProductUpdate
from app.services.file_storage_service import FileStorageService


class ProductService:
    def __init__(
        self,
        product_repository: ProductRepository | None = None,
        file_storage: FileStorageService | None = None,
    ) -> None:
        self.product_repository = product_repository or ProductRepository()
        self.file_storage = file_storage or FileStorageService()

    async def list_products(
        self,
        page: int,
        limit: int,
        search: str | None,
        category: str | None,
    ) -> dict:
        query = self._build_query(search, category)
        skip = (page - 1) * limit
        products, total = await self.product_repository.list(query, skip, limit)
        return {
            "success": True,
            "data": {
                "products": [self.public_product(product) for product in products],
                "pagination": {"page": page, "limit": limit, "total": total},
            },
        }

    async def create_product(self, payload: ProductCreate, user: dict) -> dict:
        now = datetime.now(timezone.utc)
        product = {
            "name": payload.name.strip(),
            "price": payload.price,
            "currency": payload.currency.strip().upper(),
            "category": payload.category.strip(),
            "imageUrl": None,
            "createdBy": object_id(user["id"]),
            "createdAt": now,
            "updatedAt": now,
        }
        product_id = await self.product_repository.create(product)
        return {
            "success": True,
            "message": "Product created successfully",
            "data": {"id": product_id},
        }

    async def get_product(self, product_id: str) -> dict:
        product = await self._find_product_or_404(product_id)
        return {"success": True, "data": self.public_product(product)}

    async def update_product(self, product_id: str, payload: ProductUpdate) -> dict:
        updates = {
            key: value
            for key, value in payload.model_dump(exclude_none=True).items()
        }
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No updates provided")
        if "currency" in updates:
            updates["currency"] = updates["currency"].strip().upper()
        if "name" in updates:
            updates["name"] = updates["name"].strip()
        if "category" in updates:
            updates["category"] = updates["category"].strip()

        updates["updatedAt"] = datetime.now(timezone.utc)
        updated = await self.product_repository.update(self._product_object_id(product_id), updates)
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        return {"success": True, "message": "Product updated successfully"}

    async def delete_product(self, product_id: str) -> None:
        deleted = await self.product_repository.delete(self._product_object_id(product_id))
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    async def upload_image(self, product_id: str, image: UploadFile) -> dict:
        product_object_id = self._product_object_id(product_id)
        filename = await self.file_storage.save_product_image(image)
        image_url = self.file_storage.public_url(filename)
        updated = await self.product_repository.update(
            product_object_id,
            {"imageUrl": image_url, "updatedAt": datetime.now(timezone.utc)},
        )
        if not updated:
            self.file_storage.delete_quietly(filename)
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        return {"success": True, "imageUrl": image_url}

    def public_product(self, document: dict) -> dict:
        product = serialize_id(document)
        product["createdBy"] = str(product["createdBy"])
        product["currency"] = product.get("currency", "USD")
        return product

    def _build_query(self, search: str | None, category: str | None) -> dict:
        query: dict = {}
        clean_search = search.strip() if search else ""
        clean_category = category.strip() if category else ""
        if clean_search:
            query["name"] = {"$regex": re.escape(clean_search), "$options": "i"}
        if clean_category:
            query["category"] = clean_category
        return query

    async def _find_product_or_404(self, product_id: str) -> dict:
        product = await self.product_repository.find_by_id(self._product_object_id(product_id))
        if product is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        return product

    def _product_object_id(self, product_id: str):
        try:
            return object_id(product_id)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found") from exc
