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

## 下一阶段

- 索引优化：用 EXPLAIN 验证慢查询
- 可选：用 Node.js 写 REST API
