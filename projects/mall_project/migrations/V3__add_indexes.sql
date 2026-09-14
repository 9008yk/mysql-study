-- mall_project V3：索引优化
-- 原则：先建新的组合/覆盖索引，再删除被覆盖的旧索引，
-- 避免外键在切换过程中失去可用索引。

USE mall_project;

-- 1. 用户订单：支持 WHERE user_id = ? ORDER BY created_at
ALTER TABLE orders
  ADD KEY idx_orders_user_created (user_id, created_at);

-- 2. 订单状态 + 时间：支持 WHERE status IN (...) AND created_at 范围
ALTER TABLE orders
  ADD KEY idx_orders_status_created (status, created_at);

-- 3. 删除被上面组合索引最左前缀覆盖的旧索引
ALTER TABLE orders
  DROP KEY idx_orders_user,
  DROP KEY idx_orders_status;

-- 4. 订单明细按商品聚合的覆盖索引
ALTER TABLE order_items
  ADD KEY idx_order_items_product_covering
    (product_id, order_id, quantity, unit_price);

-- 5. 删除被新索引最左前缀覆盖的旧索引
ALTER TABLE order_items
  DROP KEY idx_order_items_product;
