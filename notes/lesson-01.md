# 第 1 课：认识数据库与 SQL

## 1. 数据库是什么

数据库是用来**持久化存储和管理数据**的软件。MySQL 是关系型数据库：数据以表格形式组织。

几个核心概念：

- **数据库（database）**：数据的大容器
- **表（table）**：一张二维表格，有行和列
- **行（row）**：一条完整记录，比如一个学生
- **列（column）**：记录的某个属性，比如姓名、年龄
- **主键（primary key）**：唯一标识一行数据的列，比如 `id`

## 2. SQL 是什么

SQL 是操作关系型数据库的标准语言。按用途分为四类：

| 分类 | 全称 | 作用 | 例子 |
| --- | --- | --- | --- |
| DDL | Data Definition Language | 定义结构 | `CREATE`、`ALTER`、`DROP` |
| DML | Data Manipulation Language | 操作数据 | `INSERT`、`UPDATE`、`DELETE` |
| DQL | Data Query Language | 查询数据 | `SELECT` |
| DCL | Data Control Language | 权限控制 | `GRANT`、`REVOKE` |

本课先掌握 DDL 和 DML，下一课重点学 DQL。

## 3. 连接数据库

用命令行连接：

```powershell
docker compose exec mysql mysql -uroot -p
```

输入本地 `.env` 中配置的 `MYSQL_ROOT_PASSWORD` 后进入 `mysql>` 交互模式。

也可以使用图形工具（DBeaver、DataGrip、MySQL Workbench）连接：

- 主机：`127.0.0.1`
- 端口：`3307`
- 用户：`root`
- 密码：本地 `.env` 中的 `MYSQL_ROOT_PASSWORD`

## 4. 第一段 SQL

```sql
-- 查看所有数据库
SHOW DATABASES;

-- 使用数据库
USE study_db;

-- 查看当前数据库里的表
SHOW TABLES;
```

SQL 语句以分号 `;` 结尾。关键字建议大写（习惯），也可以小写，MySQL 不区分。

## 5. 建表、插入、查询、修改、删除

完整练习见 `projects/lesson-01.sql`。核心语句：

```sql
CREATE TABLE students (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  age INT,
  email VARCHAR(100),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (name, age, email) VALUES
('张三', 18, 'zhangsan@example.com');

SELECT * FROM students;

UPDATE students SET age = 19 WHERE name = '张三';

DELETE FROM students WHERE id = 1;
```

注意：`UPDATE` 和 `DELETE` 的 `WHERE` 非常关键，漏掉会作用于全表。

## 作业

打开 `projects/lesson-01.sql`，自己动手执行，然后回答三个问题：

1. `AUTO_INCREMENT` 的作用是什么？
2. 为什么 `id` 要设置为主键？
3. 如果 `DELETE FROM students` 不加 `WHERE`，会发生什么？
