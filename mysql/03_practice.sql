-- 第 5 课：索引与优化 - 练习
-- 先跑 01_setup.sql 和 02_explain_demo.sql，再独立完成这些练习。
-- 每个题目先用 EXPLAIN 看执行计划，再写出“为什么”或“如何改写”。

USE index_study;

-- 练习 1：按手机号查用户。
-- 预期：type = const，key = uk_phone。说明唯一索引等值查询可以直接命中一行。
EXPLAIN SELECT id, username FROM users WHERE phone = '13800012345';

-- 练习 2：统计每个城市的用户数。
-- 预期：type = index，key = idx_city_age，Extra 含 Using index。
-- 城市列是组合索引最左列，且只需 city，索引覆盖查询，不用回表。
EXPLAIN SELECT city, COUNT(*) AS cnt
FROM users
GROUP BY city;

-- 练习 3：查 2024 年 7 月下单的订单。
-- 预期：type = range，key = idx_created_at。范围查询可以走索引。
EXPLAIN SELECT order_no, amount
FROM orders
WHERE created_at >= '2024-07-01'
  AND created_at < '2024-08-01';

-- 练习 4：查每个用户的订单数，只看订单数最多的 5 个用户。
-- 预期：type = index，key = idx_user_id（只扫索引，不扫整张表）。
EXPLAIN SELECT user_id, COUNT(*) AS order_cnt
FROM orders
GROUP BY user_id
ORDER BY order_cnt DESC
LIMIT 5;

-- 练习 5：索引失效排查。
-- 下面这条虽然“结果对”，但函数包住 created_at，无法走 range 精确查找；
-- 因为 COUNT(*) 只需要索引，它最多只能变成“扫整个索引”，性能仍然很差。
EXPLAIN SELECT COUNT(*) FROM users WHERE YEAR(created_at) = 2024;

-- 请改写成能用 idx_created_at 的范围查询，再用 EXPLAIN 验证：
-- SELECT COUNT(*) FROM users
-- WHERE created_at >= '2024-01-01'
--   AND created_at < '2025-01-01';

-- 练习 6：给 email 加索引，观察执行计划变化。
-- 先看“没索引”的样子，预期 type = ALL：
EXPLAIN SELECT * FROM users WHERE email = 'user12345@example.com';

-- 然后手工执行下面这条 ALTER 加索引：
-- ALTER TABLE users ADD KEY idx_email (email);
-- 加完后再跑一次 EXPLAIN，预期 type = ref，key = idx_email：
-- EXPLAIN SELECT * FROM users WHERE email = 'user12345@example.com';
-- 提示：如果重复练习时索引已存在，ALTER 会报错，可忽略或先删掉再重建。

-- 思考题：
-- gender 只有 M/F 两个值，区分度极低（2 / 10 万）。
-- 为什么不值得单独建索引？
-- 实验参考（已实际跑过）：
--   没索引：type = ALL，Extra = Using temporary
--   有 idx_gender：type = index，key = idx_gender，rows 仍约 10 万，Extra = Using index
-- 它仍然要扫完整棵索引，只是省掉了临时分组；如果按 gender 过滤，
-- WHERE gender = 'M' 会命中约一半行（rows ≈ 49830），索引定位后还要大量回表，
-- 节省不多，却让每次写入都多维护一棵树。收益小、成本大。
EXPLAIN SELECT gender, COUNT(*) AS cnt FROM users GROUP BY gender;
