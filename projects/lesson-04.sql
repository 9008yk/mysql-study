-- 第 4 课练习：事务
-- 用法：进入容器后执行 source /scripts/lesson-04.sql

USE study_db;

-- 0. 准备一张练习账户表（学习环境专用，不碰业务表）
DROP TABLE IF EXISTS lesson4_accounts;

CREATE TABLE lesson4_accounts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  account_name VARCHAR(50) NOT NULL,
  balance DECIMAL(12, 2) NOT NULL
) COMMENT '事务练习账户表';

INSERT INTO lesson4_accounts (account_name, balance) VALUES
('Alice', 1000.00),
('Bob', 1000.00);

-- 1. 查看初始数据
SELECT * FROM lesson4_accounts;

-- 2. 查看 autocommit：1 表示每条 SQL 默认自动提交
SELECT @@autocommit AS autocommit;

-- 3. 查看当前隔离级别：MySQL 8 默认 REPEATABLE READ
SELECT @@transaction_isolation AS isolation_level;

-- 4. 正常转账 + COMMIT
START TRANSACTION;
UPDATE lesson4_accounts SET balance = balance - 200 WHERE id = 1;
UPDATE lesson4_accounts SET balance = balance + 200 WHERE id = 2;
COMMIT;

-- 查看提交后的数据
SELECT * FROM lesson4_accounts;

-- 5. 转账中途反悔 + ROLLBACK
START TRANSACTION;
UPDATE lesson4_accounts SET balance = balance - 500 WHERE id = 1;
UPDATE lesson4_accounts SET balance = balance + 500 WHERE id = 2;

-- 事务内能看到修改后的临时值
SELECT * FROM lesson4_accounts;

ROLLBACK;

-- 回滚后恢复原状
SELECT * FROM lesson4_accounts;

-- 6. SAVEPOINT 部分回滚
START TRANSACTION;
UPDATE lesson4_accounts SET balance = balance - 100 WHERE id = 1;
SAVEPOINT after_step1;
UPDATE lesson4_accounts SET balance = balance + 100 WHERE id = 2;
ROLLBACK TO SAVEPOINT after_step1;
COMMIT;

-- 最终结果：只保留了存档点之前的修改
SELECT * FROM lesson4_accounts;
