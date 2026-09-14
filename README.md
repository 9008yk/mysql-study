# MySQL 学习项目

跟着 AI 学习 MySQL：环境、练习、笔记和项目都放在这个目录。

## 环境

- MySQL 8.0，运行在 Docker Desktop 中
- 宿主机端口：`3307`（本机 `3306` 已被 Windows 上的 MySQL 服务占用）
- 用户名 / 密码：`root` / 本地 `.env` 中的 `MYSQL_ROOT_PASSWORD`
- 默认数据库：`study_db`

## 常用命令

在项目根目录执行：

```powershell
# 启动数据库
docker compose up -d

# 查看状态
docker compose ps

# 进入 MySQL 命令行
docker compose exec mysql mysql -uroot -p

# 停止数据库
docker compose down

# 停止并删除数据卷（会清空所有学习数据，慎用）
docker compose down -v
```

## 学习进度

- [x] 第 1 课：认识数据库与 SQL（`notes/lesson-01.md`）
- [x] 第 2 课：查询进阶（`notes/lesson-02.md`）
- [x] 第 3 课：多表查询（`notes/lesson-03.md`）
- [x] 第 4 课：事务（`notes/lesson-04.md`）
- [x] 第 5 课：索引与优化（`mysql/README.md`）
- [ ] 项目实战（数据库阶段完成，待 Node.js API：`projects/mall_project/`）
