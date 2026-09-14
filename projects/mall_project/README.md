# 商城项目：订单管理系统

项目实战第一课：从需求出发设计数据库，再用版本化迁移脚本建库建表。

## 业务需求

- 用户可以在商城购买商品
- 每张订单可以包含多个商品明细
- 商品属于某个分类
- 需要支持查询订单、统计商品销量、统计分类销售额
- 后续会实现“下单扣库存”的事务场景

## 表关系

```text
categories 1 - N products 1 - N order_items N - 1 orders N - 1 users
```

- `categories`：商品分类
- `products`：商品，包含价格、成本、库存
- `users`：用户
- `orders`：订单主表，记录用户、总金额、状态
- `order_items`：订单明细，记录每件商品的数量和成交单价

## 设计要点

- 金额使用 `DECIMAL`，不用 `FLOAT` / `DOUBLE`
- 订单明细保存 `unit_price` 成交单价，不依赖商品当前价格
- `orders.total_amount` 是冗余汇总字段，方便高频查询，由种子数据保证和明细一致
- 外键保证数据完整性：商品必须属于存在的分类，订单必须属于存在的用户
- 高频查询列建了索引：`category_id`、`user_id`、`status`、`created_at`

## 迁移脚本

```text
migrations/
  V1__create_tables.sql   建库建表
  V2__seed_data.sql       测试数据
  V3__add_indexes.sql     索引优化
```

进入项目根目录执行：

```powershell
docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4 -e "source /scripts/mall_project/migrations/V1__create_tables.sql"'
docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4 -e "source /scripts/mall_project/migrations/V2__seed_data.sql"'
```

企业里迁移文件按版本顺序只执行一次，不会反复重跑。

## 业务查询

```text
queries/
  01_business_queries.sql   商城常用业务查询
  02_explain.sql            EXPLAIN 执行计划演示
  03_transaction_demo.sql   下单扣库存事务演示
```

- 用户订单列表
- 商品销量排行
- 分类销售额
- 高价值用户 TOP10
- 订单状态统计
- 按月销售统计

统计销售额时，只统计有效订单：`paid`、`completed`、`shipped`。

## 事务实战

`03_transaction_demo.sql` 用存储过程实现“下单扣库存”：

```text
开启事务
-> 锁定商品行并检查库存
-> 扣减库存
-> 插入订单
-> 插入订单明细
-> 汇总金额
-> 提交事务
```

库存不足时抛出错误，整个事务回滚，库存和订单都不会变化。
演示结束后会自动清理测试订单、恢复库存，方便重复运行。

## 索引优化

V3 做了三组调整：

```text
orders:
  (user_id, created_at)    支持用户订单按时间查询
  (status, created_at)     支持状态筛选加时间范围

order_items:
  (product_id, order_id, quantity, unit_price)
  支持按商品聚合销量和销售额，并覆盖查询所需列
```

新索引建立后，删除了被最左前缀覆盖的旧单列索引，避免重复索引增加写入成本。
小表上 MySQL 可能仍然选择全表扫描，这是优化器的正常选择；
数据量变大后，组合索引和覆盖索引的价值才会明显体现。

EXPLAIN 对比结果：

```text
订单明细聚合：
  优化前：key=idx_order_items_product，Extra=NULL
  优化后：key=idx_order_items_product_covering，Extra=Using index

用户订单关联：
  优化前：key=idx_orders_user
  优化后：key=idx_orders_user_created

商品表：
  仍然可能 type=ALL
  因为当前只有 12 行，全表扫描比走索引回表更便宜
```

## 下一阶段

- 完善 API 测试
- 用 Dockerfile 把 FastAPI 服务容器化
- 增加用户注册、支付、取消订单等业务
- 部署到服务器或云平台

## FastAPI API

API 目录：

```text
api/
  app/
    main.py
    database.py
    models.py
    schemas.py
    routers/
  tests/
  .env.example
  requirements.txt
  README.md
```

当前接口：

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/health` | 健康检查 |
| GET | `/products` | 商品列表 |
| GET | `/products/{id}` | 商品详情 |
| GET | `/orders` | 订单列表 |
| GET | `/orders/{id}` | 订单详情 |
| POST | `/orders` | 事务下单扣库存 |
| GET | `/reports/category-sales` | 分类销售额 |
| GET | `/reports/product-sales` | 商品销量排行 |

启动方式见 `api/README.md`。
