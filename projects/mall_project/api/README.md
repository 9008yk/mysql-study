# Mall Project API

基于 FastAPI + SQLAlchemy 2.0 + PyMySQL 的商城接口。

## 环境要求

- Python 3.13+
- MySQL 容器 `mysql-study` 正常运行
- 已执行 `mall_project` 的 V1、V2、V3 迁移

## 安装

在 `projects/mall_project/api` 目录执行：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## 配置

复制 `.env.example` 为 `.env`，填入本地数据库密码：

```env
DATABASE_URL=mysql+pymysql://root:你的密码@127.0.0.1:3307/mall_project?charset=utf8mb4
```

`.env` 已被 Git 忽略，不要提交。

## 启动

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

打开 API 文档：

```text
http://127.0.0.1:8000/docs
```

## 接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/health` | 健康检查 |
| GET | `/products` | 商品列表 |
| GET | `/products/{id}` | 商品详情 |
| GET | `/orders` | 订单列表，可按用户和状态筛选 |
| GET | `/orders/{id}` | 订单详情和明细 |
| POST | `/orders` | 事务下单扣库存 |
| GET | `/reports/category-sales` | 分类销售额 |
| GET | `/reports/product-sales` | 商品销量排行 |

## 示例

```powershell
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/products
curl http://127.0.0.1:8000/reports/category-sales

curl -X POST http://127.0.0.1:8000/orders `
  -H "Content-Type: application/json" `
  -d '{"user_id":1,"product_id":1,"quantity":1,"address":"Shanghai"}'
```

## 测试

```powershell
pytest -q
```

测试会真实访问 MySQL，并在测试结束后清理测试订单、恢复库存。
