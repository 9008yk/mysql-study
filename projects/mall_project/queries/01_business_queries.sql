-- mall_project 业务查询
-- 统计销售额时只统计有效订单：paid / completed / shipped

USE mall_project;

-- 1. 用户订单列表：最近 10 张订单
SELECT u.username,
       o.order_no,
       o.total_amount,
       o.status,
       o.created_at
FROM users u
JOIN orders o ON o.user_id = u.id
ORDER BY o.created_at DESC
LIMIT 10;

-- 2. 商品销量排行：按有效订单的销售额排序
SELECT p.name AS product_name,
       SUM(oi.quantity) AS total_quantity,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'completed', 'shipped')
GROUP BY p.id, p.name
ORDER BY revenue DESC;

-- 3. 分类销售额：只统计有效订单
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

-- 4. 高价值用户 TOP10：未支付订单计入订单数，但不计入消费
SELECT u.username,
       COUNT(o.id) AS order_count,
       IFNULL(SUM(
         CASE WHEN o.status IN ('paid', 'completed', 'shipped')
              THEN o.total_amount ELSE 0 END
       ), 0) AS total_spend
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY total_spend DESC, order_count DESC
LIMIT 10;

-- 5. 订单状态统计
SELECT status,
       COUNT(*) AS order_count,
       SUM(total_amount) AS total_amount
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- 6. 订单明细列表：订单 + 用户 + 商品
SELECT o.order_no,
       u.username,
       p.name AS product_name,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN users u ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.order_no, p.id
LIMIT 15;

-- 7. 按月销售统计
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month,
       COUNT(*) AS order_count,
       SUM(total_amount) AS revenue
FROM orders
WHERE status IN ('paid', 'completed', 'shipped')
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;

-- 8. 每个用户订单数和累计金额
SELECT u.username,
       COUNT(o.id) AS order_count,
       IFNULL(SUM(o.total_amount), 0) AS total_amount
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY total_amount DESC;
