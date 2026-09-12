# MySQL 第 5 课：索引机制与优化

> 配套脚本：
> - `01_setup.sql`：建库、建表、造数据
> - `02_explain_demo.sql`：EXPLAIN 执行计划演示
> - `03_practice.sql`：练习与自测
>
> 运行环境：Docker 容器 `mysql-study`，MySQL `8.0.46`，宿主机端口 `3307`

## 0. 环境检查结果

```powershell
docker ps
```

```text
NAMES        IMAGE       PORTS                    STATUS
mysql-study  mysql:8.0   0.0.0.0:3307->3306/tcp   Up 27 hours (healthy)
```

确认：MySQL 正在 Docker 中运行，宿主机端口是 `3307`，容器内是 `3306`。
本课使用独立数据库 `index_study`，不会碰 `study_db` 里已有的真实业务表。

## 1. 为什么要索引

没有索引时，查询 `WHERE email = '...'` 只能把整张表逐行读一遍，这叫**全表扫描（ALL）**。
数据少的时候无所谓，数据到 10 万、100 万、1000 万行后，逐行扫描会越来越慢。

索引可以理解为“书前面的目录”：

- 书页很多，但目录已经按顺序排好，可以很快翻到目标章节
- 目录本身占用额外纸张，维护目录也需要成本

所以索引是**用存储空间和写入成本，换查询速度**。它不是越多越好。

## 2. 基础：InnoDB 与 B+ 树

MySQL 8 默认存储引擎是 InnoDB，数据不是按“一行一文件”存的，而是存在**页（page）**里，
默认每页 16KB。B+ 树是 InnoDB 索引的底层结构：

- 树是有序的，左小右大，所以等值、范围、排序都能利用顺序
- 树非常“矮”，一般 3 到 4 层就能覆盖几百万甚至几千万条记录
- 每次查询只需要从根节点往下走几层，每层一次磁盘读取，而不是扫所有页

```text
            根节点（几十~几百个指针）
              /        |        \
         内部节点    内部节点    内部节点
          /  \        /  \       /  \
       叶子 叶子    叶子 叶子   叶子 叶子   <- 叶子节点按顺序连在一起
```

## 3. 聚簇索引、二级索引、回表

先用“书”来打比方：

- 把整张表想成一本“正文按页码排列”的书
- 主键（`id`）就是页码
- **聚簇索引**：正文就存在这棵索引树里，按页码翻到，正文就在眼前
- **二级索引**：书末尾的“关键词索引”，只写“关键词 -> 页码”，不写正文
- **回表**：从关键词索引查到页码后，再翻回正文那一页去取正文

### 聚簇索引

InnoDB 表默认按主键建一棵 B+ 树，这棵树叫**聚簇索引**。
它的叶子节点直接存“完整的一行数据”，所以：

```sql
SELECT * FROM users WHERE id = 12345;
```

MySQL 在主键树上定位到 `id = 12345`，叶子节点里就是这一整行，
不需要再查任何别的地方。执行计划是 `type = const`，`key = PRIMARY`。

每张 InnoDB 表只有一个聚簇索引，通常就是主键。

### 二级索引

`idx_city_age (city, age)` 这样的普通索引叫**二级索引**。
它也是 B+ 树，但叶子节点不存整行，只存：

```text
索引列(city, age) + 主键 id
```

还是用 `users` 表举例，`idx_city_age` 的叶子节点大致长这样：

```text
('北京', 30, id=12345)
('北京', 30, id=67890)
('上海', 25, id=22222)
...
```

关键是：**二级索引里只有索引列和主键，没有 username、phone、email 这些其他列**。

### 回表

执行：

```sql
SELECT * FROM users WHERE city = '北京' AND age = 30;
```

因为 `SELECT *` 需要 `username`、`phone`、`email` 等完整列，
而二级索引里没有这些列，MySQL 必须分两步：

1. 在 `idx_city_age` 树里找到 `('北京', 30)`，得到一串主键 `id`
2. 拿每个 `id` 回到聚簇索引树，把完整行取出来

第 2 步就叫**回表**。演示环境里大约有 189 个用户满足条件，
所以这条查询要回表约 189 次，每次都是一次额外的 B+ 树查找。

如果查询要的列恰好全在二级索引里，就不需要回表：

```sql
SELECT city, age FROM users WHERE city = '北京' AND age = 30;
-- Extra: Using index，覆盖索引，不回表
```

因为 `city` 和 `age` 本来就在 `idx_city_age` 的叶子节点里，MySQL 不用再去聚簇索引。
这种“索引里的内容已经够用”的索引就叫**覆盖索引**。

## 4. 索引类型

先记住一个思路：**索引类型主要回答三个问题**：

1. 这个索引允不允许重复？
2. 它管一列还是多列？
3. 它存整个值，还是只存一部分？

### 主键索引 PRIMARY KEY

每张表只有一个，自动唯一、不允许 NULL，同时就是聚簇索引：

```sql
PRIMARY KEY (id)
```

叶子节点直接存整行，所以 `WHERE id = 12345` 最快，执行计划是 `const`。

### 唯一索引 UNIQUE KEY

值不允许重复，但允许 NULL（NULL 可以有多行）。它既约束数据，又加速查询：

```sql
UNIQUE KEY uk_phone (phone)
```

插入重复手机号会报错；`WHERE phone = '13800012345'` 可以走唯一索引。

### 普通索引 KEY / INDEX

不限制重复，只用来加速查询，可以建很多个：

```sql
KEY idx_created_at (created_at)
```

`created_at` 有很多相同值也能建索引，只是查出来可能有多行。

### 组合索引 KEY (列1, 列2)

把多个列放进同一棵 B+ 树，适合同时过滤多个条件的查询：

```sql
KEY idx_city_age (city, age)
```

遵守最左前缀：`(city, age)` 能服务 `city`，也能服务 `city + age`，
但不能单独服务 `age`（见第 8 节）。

### 前缀索引

只索引字符串的前 N 个字符，例如 `email(10)`，目的是省空间。
代价是区分度可能降低。本课没有演示，知道“可以只索引一部分”即可。

### 全文索引 FULLTEXT

专门用于文章、搜索场景，做分词和关键词搜索。
普通查询 `WHERE content = '...'` 用不到它，本课没有演示。

### 一句话总结

| 类型 | 主要作用 | 能否重复 | 管几列 |
| --- | --- | --- | --- |
| 主键索引 | 唯一标识，叶子存整行 | 不能，且非空 | 通常 1 列 |
| 唯一索引 | 防重复 + 加速 | 不能 | 1 列或多列 |
| 普通索引 | 只加速 | 能 | 1 列或多列 |
| 组合索引 | 多条件一起加速 | 看是否唯一 | 多列 |
| 前缀索引 | 省空间 | 不一定 | 1 列的前 N 个字符 |
| 全文索引 | 长文本搜索 | 不适用 | 1 列 |

## 5. EXPLAIN 怎么看

`EXPLAIN` 是 MySQL 的诊断工具：在一条 `SELECT` 前面加上 `EXPLAIN`，
MySQL 不会真的执行查询，而是告诉你“它打算怎么找数据”。

```sql
EXPLAIN SELECT * FROM users WHERE id = 12345;
```

返回结果是一张表，每一行代表一次“找数据”的动作。刚入门只看四列就够了。

### type：用哪种方式找数据

`type` 从好到差，最常见的几个：

| type | 中文理解 | 什么时候出现 | 本课例子 |
| --- | --- | --- | --- |
| `const` | 最多只找到 1 行，常数级 | 主键/唯一索引等值 | `WHERE id = 12345` |
| `eq_ref` | 连接时按主键/唯一索引找另一张表的 1 行 | JOIN 的关联表 | 订单连接用户，用户按主键回查 |
| `ref` | 用索引找多行 | 普通索引等值 | `WHERE city = '北京'` |
| `range` | 用索引按范围找 | `>`、`<`、`BETWEEN`、前缀 `LIKE` | `WHERE created_at >= ...` |
| `index` | 把整棵索引树扫一遍 | 索引能覆盖查询，但没法定位 | `ORDER BY created_at LIMIT 10` |
| `ALL` | 把整张表扫一遍，最差 | 没索引或用不上索引 | `WHERE email = '...'` |

不用背顺序，先记住：`const`、`ref`、`range` 是“走索引”，
`ALL` 是“整表扫”，是慢查询最常见的信号。

### key 和 rows

- `key`：这次真的用了哪个索引；`NULL` 表示没用索引
- `rows`：优化器预估要检查多少行，只是估算，越小越好

### Extra：额外的提示

| Extra | 含义 | 是好是坏 |
| --- | --- | --- |
| `Using index` | 覆盖索引，不用回表 | 好 |
| `Using index condition` | 索引下推，先在索引里过滤 | 好 |
| `Using where` | 取出数据后再过滤 | 中性 |
| `Using filesort` | 排序没走索引，额外做一次排序 | 要警惕 |

### 怎么用

看到一条慢 SQL，按三个问题检查：

1. `key` 是 `NULL` 吗？是，说明没用索引
2. `type` 是 `ALL` 吗？是，说明在扫全表
3. `rows` 很大吗？是，说明要检查很多行

如果表很大、答案又总是“是”，通常应该考虑建索引或改写 SQL。

### 真实例子

```text
EXPLAIN SELECT * FROM users WHERE id = 12345;
type = const, key = PRIMARY, rows = 1

EXPLAIN SELECT * FROM users WHERE email = 'user12345@example.com';
type = ALL,  key = NULL,     rows = 99544
```

同样的表，一条一次定位，一条要扫近十万行，这就是索引和 `EXPLAIN` 的意义。

## 6. 演示表结构

```sql
CREATE TABLE users (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  username   VARCHAR(32)      NOT NULL,
  phone      CHAR(11)         NOT NULL,
  email      VARCHAR(100)     NOT NULL,          -- 故意不建索引
  city       VARCHAR(20)      NOT NULL,
  age        TINYINT UNSIGNED NOT NULL,
  gender     CHAR(1)          NOT NULL,
  created_at DATETIME         NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username),
  UNIQUE KEY uk_phone (phone),
  KEY idx_city_age (city, age),
  KEY idx_created_at (created_at)
) ENGINE = InnoDB;
```

`orders` 表额外演示组合索引和连接：

```sql
PRIMARY KEY (id),
UNIQUE KEY uk_order_no (order_no),
KEY idx_user_id (user_id),
KEY idx_user_created (user_id, created_at),
KEY idx_created_at (created_at)
```

数据量：10 万用户、20 万订单。

## 7. 真实 EXPLAIN 对照

以下是本环境实际执行的结果（行数会随统计信息略有浮动）：

| # | 查询要点 | type | key | Extra | 说明 |
| --- | --- | --- | --- | --- | --- |
| 1 | `email = '...'`（无索引） | `ALL` | NULL | `Using where` | 只能全表扫描 |
| 2 | `id = 12345` | `const` | `PRIMARY` | NULL | 主键等值，直接命中一行 |
| 3 | `username = '...'` | `const` | `uk_username` | NULL | 唯一索引等值 |
| 4 | `city = '北京' AND age = 30` | `ref` | `idx_city_age` | NULL | 组合索引全命中，扫约 189 行 |
| 5 | `city = '北京'` | `ref` | `idx_city_age` | NULL | 只用最左列也可以 |
| 6 | `age = 30` | `ALL` | NULL | `Using where` | 跳过最左列，索引用不上 |
| 7 | `SELECT city, age WHERE ...` | `ref` | `idx_city_age` | `Using index` | 覆盖索引，不回表 |
| 8 | `created_at` 范围 | `range` | `idx_created_at` | `Using index condition` | 范围查询走索引 |
| 9 | `DATE(created_at) = '...'` | `ALL` | NULL | `Using where` | 函数包住列，索引失效 |
| 10 | `LIKE '%12345'` | `ALL` | NULL | `Using where` | 前导通配符，索引失效 |
| 11 | `LIKE '北%'` | `range` | `idx_city_age` | `Using index condition` | 后缀通配符可以走 range |
| 12 | `phone = 13800012345`（数字） | `ALL` | NULL | `Using where` | 隐式类型转换，索引失效 |
| 12b | `phone = '13800012345'` | `const` | `uk_phone` | NULL | 加引号后正确走唯一索引 |
| 13 | `city = '北京' OR email = ...` | `ALL` | NULL | `Using where` | OR 里有无索引列，整体全表扫 |
| 14 | `ORDER BY created_at LIMIT 10` | `index` | `idx_created_at` | `Using index` | 按索引顺序读，避免 filesort |
| 15 | `orders JOIN users ON user_id` | `range` + `eq_ref` | `idx_created_at` + `PRIMARY` | `Using index condition` | 订单先范围查，用户按主键逐行回查 |
| 17 | `city LIKE '北%' AND age > 30` | `range` | `idx_city_age` | `Using index condition` | 索引下推，先过滤再回表 |

完整脚本见 `02_explain_demo.sql`，其中还包含 `EXPLAIN ANALYZE` 的真实耗时输出。

## 8. 最左前缀原则

组合索引 `(city, age)` 相当于先按 `city` 排序，`city` 相同再按 `age` 排序。
因此可以支持：

```sql
WHERE city = '北京'                  -- 用最左列
WHERE city = '北京' AND age = 30     -- 连续使用两列
```

但不能支持：

```sql
WHERE age = 30                       -- 跳过 city，直接查第二列
```

因为 B+ 树的叶子是“先 city、后 age”排列的，只知道 age 无法确定该从哪一段开始找。

## 9. 覆盖索引与索引下推

**覆盖索引**：查询需要的列全部在索引里，不需要回表。

```sql
EXPLAIN SELECT city, age FROM users
WHERE city = '北京' AND age = 30;
-- Extra: Using index
```

**索引下推（Index Condition Pushdown）**：组合索引 `(city, age)` 中，
`age > 30` 无法用于定位起始位置，但可以在索引内部先过滤，减少回表次数。

```sql
EXPLAIN SELECT * FROM users
WHERE city LIKE '北%' AND age > 30;
-- Extra: Using index condition
```

MySQL 5.6 起默认开启索引下推，通常不需要手动配置。

## 10. 索引失效的常见坑

1. 对索引列做函数或运算：`WHERE DATE(created_at) = '2024-06-01'`
   - 应改写成范围：`created_at >= '2024-06-01' AND created_at < '2024-06-02'`
2. 前导通配符：`LIKE '%12345'`；`_` 也属于通配符，前缀不确定也无法用索引
3. 隐式类型转换：`phone = 13800012345`，字符串列要加引号
4. `OR` 条件里混入无索引列，优化器往往选择全表扫描
5. 区分度太低：例如性别只有 M/F，扫索引再回表可能比全表扫描更贵

注意第 1 点：`SELECT COUNT(*) ... WHERE YEAR(created_at) = 2024` 可能显示
`type = index` 且 `Using index`，但那是“扫完整棵索引树”而不是范围定位，性能依然差。

## 11. 索引设计建议

- 主键尽量短小、自增、不随业务变化
- 为高频查询列建索引，为低频列和低区分度列保持克制
- 组合索引把等值条件放前面，范围条件放后面；遵守最左前缀
- 避免重复索引：`idx_user_id` 和 `idx_user_created(user_id, created_at)`
  如果后者已覆盖前者，前者通常可以删除
- 用覆盖索引优化高频只读查询，但别为了覆盖把所有列都塞进索引
- 排序、分组、连接键是索引的重要使用场景
- 业务上不要 `SELECT *`，按需取列，回表才更轻
- 深分页可用“延迟关联”或基于主键的游标分页，避免 `LIMIT 100000, 10`
- 写完 SQL 用 `EXPLAIN` 检查 `type/key/rows/Extra`，用 `ANALYZE TABLE` 更新统计信息

## 12. 作业

打开 `03_practice.sql`：

1. 手机号等值查询的执行计划是什么？为什么？
2. 按城市分组统计，能否利用 `idx_city_age`？`Extra` 里有什么？
3. 7 月订单范围查询走的是哪个索引？
4. 按用户统计订单数时，MySQL 为什么选择扫 `idx_user_id` 而不是全表？
5. 把 `YEAR(created_at) = 2024` 改写成范围查询，对比执行计划。
6. 给 `email` 加索引前后，执行计划有什么变化？
7. 思考题：为什么 `gender` 这种低区分度列通常不值得单独建索引？

## 附：常用命令

在 `D:\vue3-program\mysql-study` 目录执行：

```powershell
# 初始化/重置学习数据
Get-Content -Raw .\mysql\01_setup.sql | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'

# 跑 EXPLAIN 演示
Get-Content -Raw .\mysql\02_explain_demo.sql | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -t'

# 跑练习
Get-Content -Raw .\mysql\03_practice.sql | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -t'
```

也可以直接进入容器交互：

```powershell
docker compose exec mysql mysql -uroot -p
```

然后：

```sql
USE index_study;
EXPLAIN SELECT * FROM users WHERE id = 12345;
```
