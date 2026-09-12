-- 第 3 课练习：多表查询 JOIN
-- 用法：进入容器后执行 source /scripts/lesson-03.sql

USE study_db;

-- 1. INNER JOIN：用户和他们的订单
SELECT u.id AS user_id,
       u.username,
       o.id AS order_id,
       o.total_amount,
       o.status
FROM users u
INNER JOIN orders o ON o.user_id = u.id
ORDER BY u.id, o.id
LIMIT 10;

-- 2. LEFT JOIN：所有用户和他们的订单数
SELECT u.id,
       u.username,
       COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY order_count DESC, u.id
LIMIT 10;

-- 3. LEFT JOIN + IS NULL：没有订单的用户
SELECT u.id, u.username
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL
ORDER BY u.id;

-- 3b. 当前数据里所有用户都有订单，所以上面的结果是空集。
-- 用临时数据集演示“找没有”的写法，不落库：
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

-- 4. 三张表 JOIN：订单明细带商品名
SELECT o.id AS order_id,
       p.name AS product_name,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.id, p.id
LIMIT 10;

-- 5. 四张表 JOIN + GROUP BY：每个分类的销售额
SELECT c.name AS category_name,
       COUNT(*) AS item_count,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY revenue DESC;

-- 6. JOIN + WHERE：已支付订单按金额倒序
SELECT u.username,
       o.id AS order_id,
       o.total_amount,
       o.status
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE o.status = 'paid'
ORDER BY o.total_amount DESC
LIMIT 10;

-- 7. 每个用户累计消费（没有订单显示 0）
SELECT u.id,
       u.username,
       COUNT(o.id) AS order_count,
       IFNULL(SUM(o.total_amount), 0) AS total_spend
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY total_spend DESC, u.id
LIMIT 10;

-- 8. 从未被下单的商品
SELECT p.id, p.name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
WHERE oi.id IS NULL
ORDER BY p.id;

-- 8b. 当前数据里所有商品都被买过，所以上面的结果是空集。
-- 再用临时数据集演示一次“找没有出现过的 id”：
WITH all_products AS (
  SELECT 1 AS id UNION ALL SELECT 2 UNION ALL SELECT 3
),
ordered_products AS (
  SELECT 2 AS product_id
)
SELECT a.id AS never_ordered_product_id
FROM all_products a
LEFT JOIN ordered_products op ON op.product_id = a.id
WHERE op.product_id IS NULL
ORDER BY a.id;

-- 作业
---- 1. 每个用户的订单数和累计消费金额（没有订单的显示 0）
select u.id as 用户名,
       count(o.id) as 订单数,
       ifnull(sum(o.total_amount),0) as 累计消费金额
from users u
left join orders o on u.id=o.user_id
group by o.user_id

-- 2. 所有已支付订单，按金额从高到低，包含用户名和订单号信息
select u.username as 用户名,
       o.total_amount as 金额
from users u
join orders o on u.id=o.user_id
where o.status='paid'
order by o.total_amount desc

-- 3, 从未被下单的商品，列出商品名
select p.name as 商品名称,
    count(*)
from order_items oi
join products p on oi.product_id=p.id
group by oi.product_id

-- 4, 每个分类的下单商品件数和销售额，只保留销售额大于 10000 的分类
select c.id as 分类名,
       sum(oi.quantity) as 每类下单的商品件数,
       sum(oi.quantity*oi.unit_price) as 每类下的销售额
from order_items oi
join products p on oi.product_id=p.id
join categories c on c.id=p.category_id
group by p.category_id;
having sum(oi.quantity*oi.unit_price)>10000;