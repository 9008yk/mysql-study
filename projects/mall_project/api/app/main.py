from fastapi import Depends, FastAPI
from sqlalchemy import text
from sqlalchemy.orm import Session

from .database import get_db
from .routers import orders, products, reports


app = FastAPI(
    title="Mall Project API",
    version="1.0.0",
    description="MySQL 商城项目实战 API",
)

app.include_router(products.router)
app.include_router(orders.router)
app.include_router(reports.router)


@app.get("/health", tags=["system"])
def health(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"status": "ok"}
