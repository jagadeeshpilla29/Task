from bson import ObjectId
from pymongo import ASCENDING

from app.core.database import db


class ProductRepository:
    async def list(self, query: dict, skip: int, limit: int) -> tuple[list[dict], int]:
        total = await db.products.count_documents(query)
        cursor = (
            db.products.find(query)
            .sort("createdAt", ASCENDING)
            .skip(skip)
            .limit(limit)
        )
        products = [product async for product in cursor]
        return products, total

    async def create(self, product: dict) -> str:
        result = await db.products.insert_one(product)
        return str(result.inserted_id)

    async def find_by_id(self, product_id: ObjectId) -> dict | None:
        return await db.products.find_one({"_id": product_id})

    async def update(self, product_id: ObjectId, updates: dict) -> bool:
        result = await db.products.update_one({"_id": product_id}, {"$set": updates})
        return result.matched_count > 0

    async def delete(self, product_id: ObjectId) -> bool:
        result = await db.products.delete_one({"_id": product_id})
        return result.deleted_count > 0
