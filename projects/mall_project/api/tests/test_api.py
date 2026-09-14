from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.main import app
from app.models import Order, Product


client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_list_products():
    response = client.get("/products", params={"limit": 5})
    assert response.status_code == 200
    products = response.json()
    assert len(products) == 5
    assert products[0]["name"] == "iPhone 15 Pro"


def test_category_sales():
    response = client.get("/reports/category-sales")
    assert response.status_code == 200
    data = response.json()
    assert data[0]["category_name"] == "Electronics"
    assert data[0]["revenue"] == "293552.00"


def test_create_order_and_cleanup():
    with SessionLocal() as db:
        product = db.get(Product, 1)
        assert product is not None
        stock_before = product.stock
        price = product.price

    response = client.post(
        "/orders",
        json={
            "user_id": 1,
            "product_id": 1,
            "quantity": 1,
            "address": "API Test Address",
        },
    )

    assert response.status_code == 201
    result = response.json()
    order_id = result["order_id"]

    try:
        with SessionLocal() as db:
            product = db.get(Product, 1)
            order = db.get(Order, order_id)

            assert product is not None
            assert order is not None
            assert product.stock == stock_before - 1
            assert order.total_amount == price

    finally:
        with SessionLocal() as db:
            order = db.get(Order, order_id)
            if order is not None:
                db.delete(order)

            product = db.get(Product, 1)
            if product is not None:
                product.stock += 1

            db.commit()


def test_insufficient_stock():
    with SessionLocal() as db:
        product = db.get(Product, 1)
        assert product is not None
        stock_before = product.stock

    response = client.post(
        "/orders",
        json={
            "user_id": 1,
            "product_id": 1,
            "quantity": 500,
            "address": "API Test Address",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Insufficient stock"

    with SessionLocal() as db:
        product = db.get(Product, 1)
        assert product is not None
        assert product.stock == stock_before
