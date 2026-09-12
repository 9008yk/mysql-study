-- mall_project 执行计划演示
-- 重点看 type / key / rows

USE mall_project;

-- 1. 分类销售额：四表 JOIN + GROUP BY
EXPLAIN
SELECT c.name AS category_name,
       COUNT(DISTINCT oi.id) AS item_count,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'completed', 'shipped')
GROUP BY c.id, c.name
ORDER BY revenue DESC;

-- 2. 高价值用户：LEFT JOIN + GROUP BY
EXPLAIN
SELECT u.username,
       COUNT(o.id) AS order_count,
       IFNULL(SUM(o.total_amount), 0) AS total_spend
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY total_spend DESC;

-- 3. 商品销量排行：JOIN order_items -> products -> orders
EXPLAIN
SELECT p.name AS product_name,
       SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'completed', 'shipped')
GROUP BY p.id, p.name
ORDER BY total_quantity DESC;
