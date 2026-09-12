# 第 4 课：事务

第 3 课我们学了多表查询。但真实业务里，很多操作不是“一条 SQL”，而是一组必须一起成功、一起失败的 SQL。这就是事务。

## 1. 为什么要事务

以转账为例，一次转账包含两步：

```sql
UPDATE accounts SET balance = balance - 200 WHERE id = 1; -- 扣钱
UPDATE accounts SET balance = balance + 200 WHERE id = 2; -- 加钱
```

如果第一步执行成功，第二步执行失败，用户的钱就凭空消失了。事务要保证：**要么两步都成功，要么两步都不生效。**

## 2. 事务的四个特性 ACID

| 特性 | 英文 | 含义 |
| --- | --- | --- |
| 原子性 | Atomicity | 一组操作要么全部成功，要么全部回滚 |
| 一致性 | Consistency | 事务前后，数据始终满足约束，比如余额不能为负 |
| 隔离性 | Isolation | 多个事务并发执行时互不干扰 |
| 持久性 | Durability | 事务提交后，数据永久保存 |

## 3. 事务命令

```sql
START TRANSACTION;  -- 开启事务

UPDATE ...;         -- 业务操作
UPDATE ...;

COMMIT;             -- 提交，所有修改正式生效
```

如果中途发现错误：

```sql
ROLLBACK;           -- 回滚，撤销本次事务的所有修改
```

也可以只撤销一部分：

```sql
SAVEPOINT sp1;      -- 打一个存档点
ROLLBACK TO sp1;    -- 回滚到存档点，存档点之后的操作被撤销
```

## 4. autocommit

MySQL 默认 `autocommit = 1`，意思是每一条 SQL 都自动提交，失败不影响其他语句。

```sql
SELECT @@autocommit;
```

所以需要“多步一起成功”时，必须显式 `START TRANSACTION`。

## 5. 隔离级别

多个事务同时运行时，可能出现三类问题：

- 脏读：读到另一个事务还没提交的数据
- 不可重复读：同一个事务里两次查询同一行，结果不一样
- 幻读：同一个事务里两次范围查询，行数不一样

MySQL 四种隔离级别：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 | 并发性能 |
| --- | --- | --- | --- | --- |
| READ UNCOMMITTED | 会 | 会 | 会 | 最高 |
| READ COMMITTED | 不会 | 会 | 会 | 高 |
| REPEATABLE READ（默认） | 不会 | 不会 | InnoDB 基本避免 | 中 |
| SERIALIZABLE | 不会 | 不会 | 不会 | 最低 |

```sql
SELECT @@transaction_isolation;
```

MySQL 8 默认是 `REPEATABLE READ`。

## 6. 实际开发场景

- 转账：扣钱 + 加钱
- 下单：扣库存 + 生成订单
- 支付回调：更新订单状态 + 记录流水
- 批量更新：多张表一起改

这些场景都必须用事务，否则并发下会出现金额错误、库存超卖、状态不一致。

## 作业

打开 `projects/lesson-04.sql` 运行，然后回答：

1. 转账如果不用事务，可能发生什么？
2. 用自己的话解释 ACID 四个特性。
3. REPEATABLE READ 解决了脏读和不可重复读，但为什么生产环境不用 SERIALIZABLE？
4. SAVEPOINT 和 ROLLBACK 的区别是什么？
