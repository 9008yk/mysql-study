-- 第 2 课练习：WHERE、聚合、分组、HAVING、分页
-- 用法：进入容器后执行 source /scripts/lesson-02.sql

USE study_db;

-- 0. 重建练习订单表
-- 说明：study_db 里已经有真实业务表 orders，且被 order_items 外键引用，
-- 所以本课用独立的 sales_orders 表，避免影响原有数据。
DROP TABLE IF EXISTS sales_orders;

CREATE TABLE sales_orders (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '订单ID',
  order_no VARCHAR(20) NOT NULL COMMENT '订单号',
  product_name VARCHAR(50) NOT NULL COMMENT '商品名',
  category VARCHAR(20) NOT NULL COMMENT '分类',
  quantity INT NOT NULL COMMENT '数量',
  price DECIMAL(10, 2) NOT NULL COMMENT '单价',
  order_date DATE NOT NULL COMMENT '下单日期'
) COMMENT '订单表';

INSERT INTO sales_orders (order_no, product_name, category, quantity, price, order_date) VALUES
('ORD-001', 'MySQL课程',  '课程', 1, 199.00, '2026-08-01'),
('ORD-002', 'Java课程',   '课程', 1, 299.00, '2026-08-02'),
('ORD-003', '前端课程',   '课程', 1, 199.00, '2026-08-03'),
('ORD-004', '算法书',     '书籍', 1,  59.00, '2026-08-04'),
('ORD-005', '数据库书',   '书籍', 1,  89.00, '2026-08-05'),
('ORD-006', '机械键盘',   '工具', 1, 399.00, '2026-08-06'),
('ORD-007', '显示器',     '工具', 1,1299.00, '2026-08-07'),
('ORD-008', '笔记本支架', '工具', 3,  79.00, '2026-08-08'),
('ORD-009', '英语课',     '课程', 2,  99.00, '2026-08-09'),
('ORD-010', '小说',       '书籍', 2,  25.00, '2026-08-10');

-- 1. WHERE：且 / 或
SELECT order_no, product_name, category, price
FROM sales_orders
WHERE category = '课程' AND price >= 200;

-- 2. WHERE：区间
SELECT order_no, product_name, price
FROM sales_orders
WHERE price BETWEEN 100 AND 300;

-- 3. WHERE：命中一组值
SELECT order_no, product_name, category
FROM sales_orders
WHERE category IN ('书籍', '工具');

-- 4. WHERE：模糊匹配
SELECT order_no, product_name
FROM sales_orders
WHERE product_name LIKE '%课%';

-- 5. 去重
SELECT DISTINCT category
FROM sales_orders;

-- 6. 聚合函数
SELECT
  COUNT(*) AS order_count,
  SUM(quantity * price) AS total_amount,
  AVG(price) AS avg_price,
  MAX(price) AS max_price
FROM sales_orders;

-- 7. 分组统计：每个分类的订单数和销售额
SELECT category,
       COUNT(*) AS order_count,
       SUM(quantity * price) AS total_amount
FROM sales_orders
GROUP BY category
ORDER BY total_amount DESC;

-- 8. HAVING：只保留销售额大于 300 的分类
SELECT category,
       COUNT(*) AS order_count,
       SUM(quantity * price) AS total_amount
FROM sales_orders
GROUP BY category
HAVING SUM(quantity * price) > 300
ORDER BY total_amount DESC;

-- 9. 金额最高的前 3 个订单
SELECT product_name, quantity * price AS amount
FROM sales_orders
ORDER BY amount DESC
LIMIT 3;

-- 10. 分页：第二页，每页 3 条
SELECT id, order_no, product_name, category
FROM sales_orders
ORDER BY id
LIMIT 3 OFFSET 3;
