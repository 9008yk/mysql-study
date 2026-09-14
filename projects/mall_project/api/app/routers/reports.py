from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..database import get_db
from ..schemas import CategorySalesOut, ProductSalesOut


router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/category-sales", response_model=list[CategorySalesOut])
def category_sales(db: Session = Depends(get_db)):
    rows = db.execute(
        text(
            """
            SELECT c.name AS category_name,
                   COUNT(DISTINCT oi.id) AS item_count,
                   SUM(oi.quantity * oi.unit_price) AS revenue
            FROM order_items oi
            JOIN products p ON p.id = oi.product_id
            JOIN categories c ON c.id = p.category_id
            JOIN orders o ON o.id = oi.order_id
            WHERE o.status IN ('paid', 'completed', 'shipped')
            GROUP BY c.id, c.name
            ORDER BY revenue DESC
            """
        )
    ).mappings().all()

    return [CategorySalesOut(**row) for row in rows]


@router.get("/product-sales", response_model=list[ProductSalesOut])
def product_sales(
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text(
            """
            SELECT p.name AS product_name,
                   SUM(oi.quantity) AS total_quantity,
                   SUM(oi.quantity * oi.unit_price) AS revenue
            FROM order_items oi
            JOIN products p ON p.id = oi.product_id
            JOIN orders o ON o.id = oi.order_id
            WHERE o.status IN ('paid', 'completed', 'shipped')
            GROUP BY p.id, p.name
            ORDER BY revenue DESC
            LIMIT :limit
            """
        ),
        {"limit": limit},
    ).mappings().all()

    return [ProductSalesOut(**row) for row in rows]
