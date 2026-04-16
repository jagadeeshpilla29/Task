from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile

from app.core.config import get_settings


class FileStorageService:
    def __init__(self) -> None:
        self.settings = get_settings()

    async def save_product_image(self, image: UploadFile) -> str:
        extension = Path(image.filename or "product.png").suffix.lower() or ".png"
        if extension not in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".heic"}:
            extension = ".png"

        filename = f"{uuid4().hex}{extension}"
        self.settings.upload_dir.mkdir(parents=True, exist_ok=True)
        target = self.settings.upload_dir / filename
        with target.open("wb") as buffer:
            buffer.write(await image.read())
        return filename

    def public_url(self, filename: str) -> str:
        return f"{self.settings.public_base_url}/uploads/{filename}"

    def delete_quietly(self, filename: str) -> None:
        (self.settings.upload_dir / filename).unlink(missing_ok=True)
