from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ASCENDING, TEXT

from app.core.config import get_settings

settings = get_settings()
client = AsyncIOMotorClient(settings.mongo_uri)
db: AsyncIOMotorDatabase = client[settings.mongo_db]


async def create_indexes() -> None:
    await db.users.create_index("email", unique=True)
    await db.products.create_index([("name", TEXT)])
    await db.products.create_index([("category", ASCENDING)])
    await db.products.create_index([("name", ASCENDING), ("category", ASCENDING)])
    await db.products.create_index([("createdAt", ASCENDING)])
