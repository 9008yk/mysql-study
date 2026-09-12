-- 第 5 课：索引与优化 - EXPLAIN 执行计划演示
-- 用法（在 D:\vue3-program\mysql-study 目录执行）：
--   Get-Content -Raw .\mysql\02_explain_demo.sql | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -t'

USE index_study;

-- 1. 没有索引的列：全表扫描 ALL
-- email 故意没有建索引，优化器只能逐行读 10 万条
EXPLAIN SELECT * FROM users WHERE email = 'user12345@example.com';

-- 2. 主键等值：const
-- 通过聚簇索引 B+ 树直接定位，不需要回表
EXPLAIN SELECT * FROM users WHERE id = 12345;

-- 3. 唯一索引等值：const
-- username 上唯一索引，命中最多 1 行
EXPLAIN SELECT * FROM users WHERE username = 'user_012345';

-- 4. 组合索引 (city, age)，两个条件都命中：ref
EXPLAIN SELECT * FROM users WHERE city = '北京' AND age = 30;

-- 5. 组合索引只用最左列 city：仍然能用 ref
EXPLAIN SELECT * FROM users WHERE city = '北京';

-- 6. 组合索引跳过最左列，只用 age：索引用不上，全表扫描 ALL
EXPLAIN SELECT * FROM users WHERE age = 30;

-- 7. 覆盖索引：要查的列都在索引里，Extra 显示 Using index，不回表
EXPLAIN SELECT city, age FROM users WHERE city = '北京' AND age = 30;

-- 8. 范围查询：range
EXPLAIN SELECT * FROM users
WHERE created_at >= '2024-06-01' AND created_at < '2024-07-01';

-- 9. 索引失效：函数包住索引列，无法用 B+ 树顺序查找
EXPLAIN SELECT * FROM users WHERE DATE(created_at) = '2024-06-01';

-- 10. 索引失效：前导通配符 %xxx
EXPLAIN SELECT * FROM users WHERE username LIKE '%12345';

-- 11. 后导通配符 xxx%：仍可走 range
-- 注意：只有 % 在末尾，且前缀确定时才能走索引；
-- 前缀里一旦带 _ 这类通配符，优化器通常也只能全表扫。
EXPLAIN SELECT * FROM users WHERE city LIKE '北%';

-- 12. 索引失效：隐式类型转换
-- phone 是 CHAR，却拿数字比较，字符串列会被转成数字，索引失效
EXPLAIN SELECT * FROM users WHERE phone = 13800123456;

-- 12b. 正确写法：字符串要加引号，才能走 uk_phone
EXPLAIN SELECT * FROM users WHERE phone = '13800012345';

-- 13. OR 混入无索引条件，优化器只能全表扫描
EXPLAIN SELECT * FROM users
WHERE city = '北京' OR email = 'user1@example.com';

-- 14. 排序走索引：ORDER BY created_at，避免 filesort
EXPLAIN SELECT id, created_at FROM users ORDER BY created_at LIMIT 10;

-- 15. 连接查询：orders 先按时间走 range，users 按主键逐行回查 eq_ref
EXPLAIN SELECT o.order_no, u.username
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at >= '2024-06-01' AND o.created_at < '2024-07-01';

-- 16. EXPLAIN ANALYZE：MySQL 8 直接给出真实执行耗时（示例）
EXPLAIN ANALYZE
SELECT * FROM users WHERE city = '北京' AND age = 30;

-- 17. 索引下推 ICP：Extra 显示 Using index condition
-- 先在索引里过滤 age > 30，再把少部分命中行回表，减少回表次数
EXPLAIN SELECT * FROM users
WHERE city LIKE '北%' AND age > 30;
