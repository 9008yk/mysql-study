-- mall_project V2：灌入测试数据

USE mall_project;

INSERT INTO categories (name) VALUES
('Electronics'),
('Clothing'),
('Books'),
('Home'),
('Food');

INSERT INTO products (name, category_id, price, cost_price, stock) VALUES
('iPhone 15 Pro',          1, 8999.00, 7000.00, 100),
('MacBook Air M3',         1, 10999.00, 8500.00, 60),
('AirPods Pro 2',          1, 1899.00, 1200.00, 200),
('Winter Jacket',          2, 599.00, 350.00, 150),
('Denim Jeans',            2, 299.00, 150.00, 300),
('Running Shoes',          2, 459.00, 220.00, 180),
('Computer Systems Book',  3, 139.00, 80.00, 500),
('Design Patterns Book',   3, 89.00, 50.00, 400),
('Stainless Bottle',       4, 129.00, 60.00, 350),
('Memory Foam Pillow',     4, 199.00, 90.00, 250),
('Green Tea Gift Set',     5, 168.00, 70.00, 220),
('Nut Gift Pack',          5, 128.00, 50.00, 280);

INSERT INTO users (username, email, phone) VALUES
('alice', 'alice@example.com',   '13800000001'),
('bob',   'bob@example.com',     '13800000002'),
('carol', 'carol@example.com',   '13800000003'),
('david', 'david@example.com',   '13800000004'),
('emma',  'emma@example.com',    '13800000005'),
('frank', 'frank@example.com',   '13800000006'),
('grace', 'grace@example.com',   '13800000007'),
('henry', 'henry@example.com',   '13800000008'),
('ivy',   'ivy@example.com',     '13800000009'),
('jack',  'jack@example.com',    '13800000010');

-- 生成 50 张订单，覆盖 10 个用户和 5 种状态
INSERT INTO orders (order_no, user_id, status, address, created_at)
WITH RECURSIVE seq (n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 50
)
SELECT
  CONCAT('SO', LPAD(n, 6, '0')),
  1 + MOD(n, 10),
  ELT(1 + MOD(n, 5), 'paid', 'completed', 'shipped', 'pending', 'completed'),
  CONCAT('Address ', n),
  TIMESTAMP('2025-01-01') + INTERVAL MOD(n, 180) DAY + INTERVAL MOD(n, 1440) MINUTE
FROM seq;

-- 生成 120 条订单明细，先填 0 元单价，后面统一回填商品当前价格
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
WITH RECURSIVE seq (n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 120
)
SELECT
  1 + MOD(n, 50),
  1 + MOD(n, 12),
  1 + MOD(n, 3),
  0.00
FROM seq;

-- 回填成交单价
UPDATE order_items oi
JOIN products p ON p.id = oi.product_id
SET oi.unit_price = p.price;

-- 汇总订单总金额
UPDATE orders o
JOIN (
  SELECT order_id, SUM(quantity * unit_price) AS total
  FROM order_items
  GROUP BY order_id
) t ON t.order_id = o.id
SET o.total_amount = t.total;

-- 已支付、已发货、已完成的订单补上支付时间
UPDATE orders
SET paid_at = created_at + INTERVAL 1 HOUR
WHERE status IN ('paid', 'completed', 'shipped');

ANALYZE TABLE users, products, orders, order_items, categories;
