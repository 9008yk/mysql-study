# 第 2 课：查询进阶

第 1 课我们已经会用 `SELECT` 查全部数据。这一课学习企业里最常用的查询能力：

- `WHERE` 的完整条件写法
- 聚合函数
- `GROUP BY` 分组统计
- `HAVING` 过滤分组
- `LIMIT` / `OFFSET` 分页

练习数据是一张 `sales_orders` 订单表，共 10 条订单，分为课程、书籍、工具三类。

为什么不用 `orders` 这个名字？因为 `study_db` 里已经有一张真实业务表 `orders`，还被 `order_items` 外键引用。真实数据库里，被外键依赖的表不能随便 `DROP`，这也是我们遇到的第一个“生产环境约束”，所以练习用独立表，不碰原有数据。

## 1. WHERE 进阶

`WHERE` 不只是 `=` 和 `>`，还有这些常用条件：

| 写法 | 含义 | 例子 |
| --- | --- | --- |
| `AND` / `OR` | 且 / 或 | `category = '课程' AND price >= 200` |
| `BETWEEN a AND b` | 闭区间 | `price BETWEEN 100 AND 300` |
| `IN (...)` | 命中一组值 | `category IN ('书籍', '工具')` |
| `LIKE '%x%'` | 模糊匹配 | `product_name LIKE '%课%'` |
| `IS NULL` / `IS NOT NULL` | 判断是否为空 | `email IS NULL` |

注意：空值判断不能用 `= NULL`，必须用 `IS NULL`。

## 2. 聚合函数

| 函数 | 作用 |
| --- | --- |
| `COUNT(*)` | 统计行数 |
| `SUM(列)` | 求和 |
| `AVG(列)` | 求平均 |
| `MAX(列)` | 最大值 |
| `MIN(列)` | 最小值 |

聚合函数可以把多行数据压缩成一行结果。

```sql
SELECT
  COUNT(*) AS order_count,
  SUM(quantity * price) AS total_amount,
  AVG(price) AS avg_price
FROM sales_orders;
```

`AS` 用来给结果列起别名。

## 3. GROUP BY 分组统计

聚合函数配合 `GROUP BY` 才有意义：按分类分组，再统计每个分组。

```sql
SELECT category,
       COUNT(*) AS order_count,
       SUM(quantity * price) AS total_amount
FROM sales_orders
GROUP BY category;
```

规则：`SELECT` 里出现的普通列必须出现在 `GROUP BY` 中；其余列必须被聚合函数包裹。

## 4. HAVING 过滤分组

`WHERE` 过滤的是“原始行”，发生在分组之前；`HAVING` 过滤的是“分组结果”，发生在分组之后。

```sql
SELECT category,
       COUNT(*) AS order_count,
       SUM(quantity * price) AS total_amount
FROM sales_orders
GROUP BY category
HAVING SUM(quantity * price) > 300;
```

能放进 `WHERE` 的条件就放 `WHERE`，`HAVING` 只处理聚合后的条件。

## 5. 排序与分页

```sql
SELECT product_name, quantity * price AS amount
FROM sales_orders
ORDER BY amount DESC
LIMIT 3;
```

`LIMIT 3` 表示只返回前 3 条，实现“金额最大的前 3 个订单”。

分页公式：第 `n` 页，每页 `m` 条：

```sql
LIMIT m OFFSET (n - 1) * m
```

第二页每页 3 条：

```sql
SELECT * FROM sales_orders
ORDER BY id
LIMIT 3 OFFSET 3;
```

## SQL 逻辑执行顺序

```text
FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
```

写 SQL 的顺序和它执行的顺序不一样，理解这个顺序，才能解释 `WHERE` 和 `HAVING` 的区别。

## 作业

1. 找出所有价格在 100 到 300 之间的课程订单。
2. 统计每个分类的订单数量，并按订单数量从多到少排序。
3. 找出订单金额最高的 3 个订单，包含产品名和金额。
4. 用分页查询第三页（每页 3 条）。
