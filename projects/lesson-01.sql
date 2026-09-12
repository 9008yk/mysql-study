-- 第 1 课练习：建表、插入、查询、修改、删除
-- 用法：进入容器后执行 source /scripts/lesson-01.sql
-- 插入语句:insert into students (name, age, email) values ('张三', 18, 'zhangsan@example.com');
-- 更新语句:update students set age = 20 where name = '张三';
-- 删除语句:delete from students where name = '张三';
-- 查询语句:select * from students;


-- 1. 创建数据库（不存在才创建）
CREATE DATABASE IF NOT EXISTS study_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE study_db;

-- 2. 建表
CREATE TABLE IF NOT EXISTS students (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '学生ID',
  name VARCHAR(50) NOT NULL COMMENT '姓名',
  age INT COMMENT '年龄',
  email VARCHAR(100) COMMENT '邮箱',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '学生表';

-- 3. 插入数据
INSERT INTO students (name, age, email) VALUES
('张三', 18, 'zhangsan@example.com'),
('李四', 20, 'lisi@example.com'),
('王五', 17, 'wangwu@example.com'),
('赵六', 22, 'zhaoliu@example.com'),
('钱七', 19, 'qianqi@example.com');

-- 4. 查询：查看全部
SELECT * FROM students;

-- 5. 查询：只看姓名和年龄，并按年龄倒序
SELECT name, age
FROM students
ORDER BY age DESC;

-- 6. 查询：筛选年龄大于 18 的人
SELECT name, age
FROM students
WHERE age > 18;

-- 7. 修改：李四年龄改成 21
UPDATE students
SET age = 21
WHERE name = '李四';

-- 8. 删除：删除王五这条记录
DELETE FROM students
WHERE name = '王五';

-- 9. 确认最终结果
SELECT * FROM students;
