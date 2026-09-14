from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Order, OrderItem, Product, User
from ..schemas import (
    OrderCreate,
    OrderCreateResult,
    OrderDetailOut,
    OrderItemOut,
    OrderListItem,
)


router = APIRouter(prefix="/orders", tags=["orders"])


@router.get("", response_model=list[OrderListItem])
def list_orders(
    user_id: int | None = Query(None, gt=0),
    status: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Order, User.username)
        .join(User, User.id == Order.user_id)
        .order_by(Order.created_at.desc(), Order.id.desc())
        .limit(limit)
        .offset(offset)
    )

    if user_id is not None:
        stmt = stmt.where(Order.user_id == user_id)

    if status is not None:
        stmt = stmt.where(Order.status == status)

    rows = db.execute(stmt).all()
    return [
        OrderListItem(
            id=order.id,
            order_no=order.order_no,
            username=username,
            total_amount=order.total_amount,
            status=order.status,
            created_at=order.created_at,
        )
        for order, username in rows
    ]


@router.get("/{order_id}", response_model=OrderDetailOut)
def get_order(order_id: int, db: Session = Depends(get_db)):
    row = db.execute(
        select(Order, User.username)
        .join(User, User.id == Order.user_id)
        .where(Order.id == order_id)
    ).first()

    if row is None:
        raise HTTPException(status_code=404, detail="Order not found")

    order, username = row
    item_rows = db.execute(
        select(OrderItem, Product.name)
        .join(Product, Product.id == OrderItem.product_id)
        .where(OrderItem.order_id == order_id)
        .order_by(OrderItem.id)
    ).all()

    items = [
        OrderItemOut(
            product_id=item.product_id,
            product_name=product_name,
            quantity=item.quantity,
            unit_price=item.unit_price,
            line_total=item.quantity * item.unit_price,
        )
        for item, product_name in item_rows
    ]

    return OrderDetailOut(
        id=order.id,
        order_no=order.order_no,
        username=username,
        total_amount=order.total_amount,
        status=order.status,
        address=order.address,
        created_at=order.created_at,
        paid_at=order.paid_at,
        items=items,
    )


@router.post("", response_model=OrderCreateResult, status_code=201)
def create_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
):
    try:
        user = db.get(User, payload.user_id)
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")

        product = db.execute(
            select(Product)
            .where(Product.id == payload.product_id)
            .with_for_update()
        ).scalar_one_or_none()

        if product is None:
            raise HTTPException(status_code=404, detail="Product not found")

        if product.stock < payload.quantity:
            raise HTTPException(status_code=400, detail="Insufficient stock")

        product.stock -= payload.quantity
        total_amount = product.price * payload.quantity

        order = Order(
            order_no=f"PY{uuid4().hex[:16].upper()}",
            user_id=payload.user_id,
            total_amount=total_amount,
            status="pending",
            address=payload.address,
            created_at=datetime.now(),
        )
        db.add(order)
        db.flush()

        db.add(
            OrderItem(
                order_id=order.id,
                product_id=product.id,
                quantity=payload.quantity,
                unit_price=product.price,
            )
        )

        db.commit()
        db.refresh(order)

        return OrderCreateResult(
            order_id=order.id,
            order_no=order.order_no,
            total_amount=order.total_amount,
            status=order.status,
        )

    except HTTPException:
        db.rollback()
        raise
    except Exception:
        db.rollback()
        raise
