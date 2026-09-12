# 第 3 课：多表查询 JOIN

第 2 课我们都在一张表里查询。但真实业务中，数据会拆到多张表，避免大量重复。
这一课用 `study_db` 里已有的真实表来学习 JOIN：

```text
users 1 - N orders 1 - N order_items
                        |
                        N - 1 products 1 - N categories
```

- `users`：用户
- `orders`：订单，`user_id` 指向用户
- `order_items`：订单明细，`order_id` 指向订单，`product_id` 指向商品
- `products`：商品，`category_id` 指向分类
- `categories`：商品分类

## 1. 为什么需要 JOIN

订单表只存 `user_id`，不存用户名；订单明细只存 `product_id`，不存商品名。
这样用户名改了不用改订单，商品改名也不用改历史订单。

但查询时，我们需要把分散在几张表里的数据拼起来，JOIN 就是“按关联条件把表拼接”的语法。

## 2. INNER JOIN

只返回两张表中能匹配上的行：

```sql
SELECT u.username, o.id AS order_id, o.total_amount, o.status
FROM users u
INNER JOIN orders o ON o.user_id = u.id
ORDER BY u.id, o.id;
```

如果某个用户没有订单，这个用户不会出现在结果里。

## 3. LEFT JOIN

返回左表的全部行；右表匹配不上时，用 `NULL` 填空：

```sql
SELECT u.username, o.id AS order_id, o.total_amount
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
ORDER BY u.id;
```

没有订单的用户也会出现，只是订单列是 `NULL`。

## 4. 别名

多表查询里列名容易重复，比如两个表都有 `id`。所以：

- 给表起短别名：`users u`、`orders o`、`order_items oi`
- 列名前带上表别名：`o.user_id`、`u.username`
- `ON` 条件决定两张表怎么匹配，`WHERE` 决定匹配后过滤哪些行

## 5. 三张表 JOIN

```sql
SELECT o.id AS order_id,
       p.name AS product_name,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.id, p.id;
```

JOIN 可以连续拼接多张表，每次 JOIN 都指定一个明确的关联条件。

## 6. JOIN + GROUP BY

JOIN 之后数据变成了“宽表”，依然可以继续分组统计：

```sql
SELECT c.name AS category_name,
       COUNT(*) AS item_count,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY revenue DESC;
```

注意：`SELECT` 里的普通列仍然必须出现在 `GROUP BY` 中，或者被聚合函数包裹。

## 7. 常用技巧：找出“没有”的数据

“没有订单的用户”用 `LEFT JOIN` + `WHERE 右表主键 IS NULL`：

```sql
SELECT u.id, u.username
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL
ORDER BY u.id;
```

当前 `study_db` 的数据里每个用户都有订单，所以这条查询的结果是空集，是正常情况。
为了直观看到效果，可以用不落库的临时数据集演示：

```sql
WITH all_ids AS (
  SELECT 1 AS id UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
),
has_orders AS (
  SELECT 1 AS user_id UNION ALL SELECT 3
)
SELECT a.id AS missing_user_id
FROM all_ids a
LEFT JOIN has_orders h ON h.user_id = a.id
WHERE h.user_id IS NULL
ORDER BY a.id;
```

结果只有 `2` 和 `4`，因为它们在 `has_orders` 里不存在。

同样的思路可以找“从未被购买的商品”。

## 作业

打开 `projects/lesson-03.sql`，自己再写四条查询：

1. 每个用户的订单数和累计消费金额（没有订单的显示 0）
2. 所有已支付订单，按金额从高到低，包含用户名和订单号信息
3. 从未被下单的商品，列出商品名
4. 每个分类的下单商品件数和销售额，只保留销售额大于 10000 的分类
