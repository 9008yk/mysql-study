from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class ProductOut(BaseModel):
    id: int
    name: str
    category_id: int
    price: Decimal
    stock: int
    status: str

    model_config = ConfigDict(from_attributes=True)


class OrderCreate(BaseModel):
    user_id: int = Field(gt=0)
    product_id: int = Field(gt=0)
    quantity: int = Field(gt=0, le=1000)
    address: str = Field(min_length=1, max_length=200)


class OrderCreateResult(BaseModel):
    order_id: int
    order_no: str
    total_amount: Decimal
    status: str


class OrderListItem(BaseModel):
    id: int
    order_no: str
    username: str
    total_amount: Decimal
    status: str
    created_at: datetime


class OrderItemOut(BaseModel):
    product_id: int
    product_name: str
    quantity: int
    unit_price: Decimal
    line_total: Decimal


class OrderDetailOut(BaseModel):
    id: int
    order_no: str
    username: str
    total_amount: Decimal
    status: str
    address: str
    created_at: datetime
    paid_at: datetime | None
    items: list[OrderItemOut]


class CategorySalesOut(BaseModel):
    category_name: str
    item_count: int
    revenue: Decimal


class ProductSalesOut(BaseModel):
    product_name: str
    total_quantity: int
    revenue: Decimal
