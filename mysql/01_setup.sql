-- 第 5 课：索引与优化 - 建表 + 造数据
-- 用法（在 D:\vue3-program\mysql-study 目录执行）：
--   Get-Content -Raw .\mysql\01_setup.sql | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
-- 说明：使用独立库 index_study，不碰 study_db 里的真实业务表。

CREATE DATABASE IF NOT EXISTS index_study
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE index_study;

-- 为方便重复练习，先清掉旧表
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

-- 用户表：故意混合“有索引”和“没索引”的列，方便对比
CREATE TABLE users (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  username   VARCHAR(32)      NOT NULL COMMENT '用户名',
  phone      CHAR(11)         NOT NULL COMMENT '手机号',
  email      VARCHAR(100)     NOT NULL COMMENT '邮箱（故意不建索引）',
  city       VARCHAR(20)      NOT NULL COMMENT '城市',
  age        TINYINT UNSIGNED NOT NULL COMMENT '年龄',
  gender     CHAR(1)          NOT NULL COMMENT '性别 M/F',
  created_at DATETIME         NOT NULL COMMENT '注册时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username),
  UNIQUE KEY uk_phone (phone),
  KEY idx_city_age (city, age),
  KEY idx_created_at (created_at)
) ENGINE = InnoDB COMMENT '用户表（索引演示）';

-- 订单表：user_id 有普通索引，也有组合索引 (user_id, created_at)
CREATE TABLE orders (
  id         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  order_no   VARCHAR(32)      NOT NULL COMMENT '订单号',
  user_id    INT UNSIGNED     NOT NULL COMMENT '用户ID',
  status     TINYINT          NOT NULL COMMENT '状态 0待支付 1已支付 2已发货 3已完成',
  amount     DECIMAL(10, 2)   NOT NULL COMMENT '金额',
  created_at DATETIME         NOT NULL COMMENT '下单时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_order_no (order_no),
  KEY idx_user_id (user_id),
  KEY idx_user_created (user_id, created_at),
  KEY idx_created_at (created_at),
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB COMMENT '订单表（索引演示）';

-- 造 10 万用户；递归 CTE 需要放开默认递归深度（默认 1000）
SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO users (username, phone, email, city, age, gender, created_at)
WITH RECURSIVE seq (n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT
  CONCAT('user_', LPAD(n, 6, '0')),
  CONCAT('138', LPAD(n, 8, '0')),
  CONCAT('user', n, '@example.com'),
  ELT(1 + MOD(n, 10), '北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '南京', '西安', '重庆'),
  18 + MOD(n, 53),
  IF(MOD(n, 2) = 0, 'M', 'F'),
  TIMESTAMP('2024-01-01') + INTERVAL MOD(n, 365) DAY + INTERVAL MOD(n, 1440) MINUTE
FROM seq;

-- 造 20 万订单
INSERT INTO orders (order_no, user_id, status, amount, created_at)
WITH RECURSIVE seq (n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 200000
)
SELECT
  CONCAT('SO', DATE_FORMAT(DATE('2024-01-01') + INTERVAL MOD(n, 365) DAY, '%Y%m%d'), LPAD(n, 8, '0')),
  1 + MOD(n, 100000),
  MOD(n, 4),
  ROUND(50 + MOD(n, 1000) * 1.37, 2),
  TIMESTAMP('2024-01-01') + INTERVAL MOD(n, 365) DAY + INTERVAL MOD(n, 1440) MINUTE
FROM seq;

-- 刷新统计信息，让优化器拿到准确的行数估算
ANALYZE TABLE users, orders;

-- 查看表里的索引
SHOW INDEX FROM users;
SHOW INDEX FROM orders;
