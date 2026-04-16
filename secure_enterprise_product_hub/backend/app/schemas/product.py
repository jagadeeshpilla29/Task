from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field, field_validator


class ProductCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    price: float = Field(gt=0)
    currency: str = Field(default="USD", pattern="^(USD|INR|EUR|GBP)$")
    category: str = Field(min_length=2, max_length=80)

    @field_validator("price", mode="before")
    @classmethod
    def price_must_be_number(cls, value: Any) -> Any:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Price must be a number")
        return value


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    price: float | None = Field(default=None, gt=0)
    currency: str | None = Field(default=None, pattern="^(USD|INR|EUR|GBP)$")
    category: str | None = Field(default=None, min_length=2, max_length=80)

    @field_validator("price", mode="before")
    @classmethod
    def price_must_be_number(cls, value: Any) -> Any:
        if value is None:
            return value
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Price must be a number")
        return value


class ProductResponse(BaseModel):
    id: str
    name: str
    price: float
    currency: str = "USD"
    category: str
    imageUrl: str | None = None
    createdBy: str
    createdAt: datetime
    updatedAt: datetime
