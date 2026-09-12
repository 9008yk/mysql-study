-- mall_project 第 3 阶段：事务实战 - 下单扣库存
-- 演示两个场景：
--   1. 成功下单：扣库存、插订单、插明细、提交
--   2. 库存不足：整单回滚，库存和订单都不变

USE mall_project;

-- 1. 创建下单存储过程，内部用事务保证原子性
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_order$$

CREATE PROCEDURE sp_create_order(
  IN p_user_id INT UNSIGNED,
  IN p_product_id INT UNSIGNED,
  IN p_quantity INT,
  IN p_address VARCHAR(200),
  OUT p_order_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_stock INT;
  DECLARE v_unit_price DECIMAL(10, 2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- 1. 锁定商品行并读取库存和单价
  SELECT stock, price
  INTO v_stock, v_unit_price
  FROM products
  WHERE id = p_product_id
  FOR UPDATE;

  IF v_stock IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;

  IF v_stock < p_quantity THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
  END IF;

  -- 2. 扣减库存
  UPDATE products
  SET stock = stock - p_quantity
  WHERE id = p_product_id;

  -- 3. 插入订单主表
  INSERT INTO orders (order_no, user_id, total_amount, status, address, created_at)
  VALUES (
    CONCAT('TXN', DATE_FORMAT(NOW(6), '%Y%m%d%H%i%s%f')),
    p_user_id,
    0,
    'pending',
    p_address,
    NOW()
  );

  SET p_order_id = LAST_INSERT_ID();

  -- 4. 插入订单明细
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (p_order_id, p_product_id, p_quantity, v_unit_price);

  -- 5. 汇总订单金额
  UPDATE orders
  SET total_amount = p_quantity * v_unit_price
  WHERE id = p_order_id;

  COMMIT;
END$$

-- 2. 包装过程：捕获库存不足错误，不让演示脚本中断
DROP PROCEDURE IF EXISTS sp_try_insufficient_stock$$

CREATE PROCEDURE sp_try_insufficient_stock()
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SELECT 'Transaction rolled back, stock unchanged' AS result;
  END;

  CALL sp_create_order(1, 1, 99999, 'Demo Failure', @bad_order_id);
END$$

DELIMITER ;

-- 3. 成功下单演示：用户 1 购买 2 件 iPhone 15 Pro
SELECT id, name, stock
FROM products
WHERE id = 1;

CALL sp_create_order(1, 1, 2, 'Shanghai Demo St', @order_id);

SELECT @order_id AS new_order_id;

SELECT id, name, stock
FROM products
WHERE id = 1;

SELECT order_no, user_id, total_amount, status
FROM orders
WHERE id = @order_id;

SELECT order_id, product_id, quantity, unit_price
FROM order_items
WHERE order_id = @order_id;

-- 4. 清理演示订单，恢复库存，保证练习数据可重复
DELETE FROM orders WHERE id = @order_id;
UPDATE products SET stock = stock + 2 WHERE id = 1;

SELECT id, name, stock
FROM products
WHERE id = 1;

-- 5. 失败演示：购买 99999 件，库存不足，应整体回滚
CALL sp_try_insufficient_stock();

SELECT id, name, stock
FROM products
WHERE id = 1;
