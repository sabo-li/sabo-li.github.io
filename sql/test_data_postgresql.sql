-- ============================================
-- PostgreSQL SQL优化测试数据生成脚本
-- ============================================
-- 生成 1000+ 条测试记录用于SQL优化测试
-- 包含: users, orders, products 三张表
-- 支持 PostgreSQL 12+
-- ============================================

-- 切换到测试数据库（如果不存在则创建）
-- CREATE DATABASE test_db;
-- \c test_db;

-- 清理旧数据（可选）
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS products CASCADE;

-- ============================================
-- 1. 创建用户表
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100),
    phone VARCHAR(20),
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_phone (phone),
    INDEX idx_created_at (created_at)
);

-- 生成用户数据 (1000条)
INSERT INTO users (username, email, phone, age)
SELECT
    CONCAT('user', LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')) AS username,
    CONCAT('user', LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0'), '@example.com') AS email,
    CONCAT('1', LPAD(FLOOR(RANDOM() * 9000000000 + 1000000000)::TEXT, 10, '0')) AS phone,
    FLOOR(RANDOM() * 60 + 18)::INT AS age
FROM
    generate_series(1, 1000);

-- ============================================
-- 2. 创建产品表
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_price (price),
    INDEX idx_category_price (category, price),
    INDEX idx_stock (stock),
    FULLTEXT INDEX ft_name (name) WITH (parser=english)
);

-- 生成产品数据 (500条)
INSERT INTO products (name, category, price, stock)
SELECT
    CONCAT('Product-', LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')) AS name,
    CASE FLOOR(RANDOM() * 5)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Food'
        WHEN 3 THEN 'Books'
        WHEN 4 THEN 'Home'
    END AS category,
    ROUND(RANDOM() * 1000 + 10, 2) AS price,
    FLOOR(RANDOM() * 1000 + 10)::INT AS stock
FROM
    generate_series(1, 500);

-- ============================================
-- 3. 创建订单表
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT DEFAULT 1,
    total_price DECIMAL(10, 2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    INDEX idx_order_date (order_date),
    INDEX idx_user_date (user_id, order_date),
    INDEX idx_status (status),
    INDEX idx_user_status (user_id, status),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 生成订单数据 (5000条)
INSERT INTO orders (user_id, product_id, quantity, total_price, status)
SELECT
    FLOOR(RANDOM() * 1000 + 1)::INT AS user_id,
    FLOOR(RANDOM() * 500 + 1)::INT AS product_id,
    FLOOR(RANDOM() * 5 + 1)::INT AS quantity,
    ROUND(RANDOM() * 1000 + 10, 2) AS total_price,
    CASE FLOOR(RANDOM() * 3)
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'completed'
        ELSE 'cancelled'
    END AS status
FROM
    generate_series(1, 5000);

-- ============================================
-- 4. 查看数据统计
-- ============================================
-- SELECT 'Users Table Statistics' AS info;
-- SELECT COUNT(*) AS total_users FROM users;
-- SELECT COUNT(*) AS users_with_phone FROM users WHERE phone IS NOT NULL AND phone != '';
-- SELECT COUNT(*) AS users_with_email FROM users WHERE email IS NOT NULL AND email != '';
-- SELECT * FROM users ORDER BY id LIMIT 3;

-- SELECT 'Products Table Statistics' AS info;
-- SELECT COUNT(*) AS total_products FROM products;
-- SELECT COUNT(*) AS products_in_electronics FROM products WHERE category = 'Electronics';
-- SELECT AVG(price) AS avg_price FROM products;
-- SELECT * FROM products ORDER BY price DESC LIMIT 3;

-- SELECT 'Orders Table Statistics' AS info;
-- SELECT COUNT(*) AS total_orders FROM orders;
-- SELECT COUNT(*) AS pending_orders FROM orders WHERE status = 'pending';
-- SELECT COUNT(*) AS completed_orders FROM orders WHERE status = 'completed';
-- SELECT user_id, COUNT(*) AS order_count FROM orders GROUP BY user_id ORDER BY order_count DESC LIMIT 10;

-- SELECT 'Table Sizes' AS info;
-- SELECT
--     schemaname || '.' || relname AS "Table",
--     pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS "Size"
-- FROM pg_stat_user_tables
-- WHERE schemaname = 'public'
-- ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC;

-- ============================================
-- 5. 创建性能测试表（用于深分页测试）
-- ============================================
CREATE TABLE IF NOT EXISTS big_table (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    data VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_user_created (user_id, created_at)
);

-- 生成 100000 条数据用于深分页测试
INSERT INTO big_table (user_id, data)
SELECT
    FLOOR(RANDOM() * 1000 + 1)::INT AS user_id,
    CONCAT('Sample data - ', MD5(RANDOM()::TEXT)) AS data
FROM
    generate_series(1, 100000);

-- 创建查询统计视图
CREATE OR REPLACE VIEW query_stats AS
SELECT
    query_text,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
WHERE query_text NOT LIKE '%pg_stat_statements%'
  AND query_text NOT LIKE '%SHOW%'
  AND query_text NOT LIKE '%RESET%'
ORDER BY mean_time DESC
LIMIT 20;

-- ============================================
-- 6. 测试函数（用于函数包裹字段优化案例）
-- ============================================

-- 6.1 创建统计函数
CREATE OR REPLACE FUNCTION get_user_count_by_age_range(min_age INT, max_age INT)
RETURNS INT AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM users WHERE age >= min_age AND age <= max_age);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- 6.2 创建排序函数
CREATE OR REPLACE FUNCTION get_top_users(limit_num INT)
RETURNS TABLE(id INT, username VARCHAR, email VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT id, username, email
    FROM users
    ORDER BY created_at DESC
    LIMIT limit_num;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. 索引类型示例
-- ============================================

-- 7.1 GIN索引示例（用于数组）
CREATE TABLE IF NOT EXISTS products_array (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    tags TEXT[] NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tags GIN (tags)
);

INSERT INTO products_array (name, tags)
SELECT
    CONCAT('Product-', LPAD(FLOOR(RANDOM() * 1000)::TEXT, 4, '0')) AS name,
    ARRAY['electronics', 'gadget', 'tech', CASE FLOOR(RANDOM() * 5)
        WHEN 0 THEN 'cheap'
        WHEN 1 THEN 'popular'
        WHEN 2 THEN 'new'
        WHEN 3 THEN 'sale'
        ELSE 'special'
    END] AS tags
FROM
    generate_series(1, 1000);

-- 7.2 BRIN索引示例（适用于时间序列数据）
CREATE TABLE IF NOT EXISTS logs (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    level VARCHAR(10) NOT NULL,
    message TEXT,
    INDEX idx_timestamp_brin (timestamp) USING BRIN
);

INSERT INTO logs (timestamp, level, message)
SELECT
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '1 year')::INTERVAL AS timestamp,
    CASE FLOOR(RANDOM() * 4)
        WHEN 0 THEN 'ERROR'
        WHEN 1 THEN 'WARN'
        WHEN 2 THEN 'INFO'
        ELSE 'DEBUG'
    END AS level,
    CONCAT('Log message - ', MD5(RANDOM()::TEXT)) AS message
FROM
    generate_series(1, 1000000);

-- ============================================
-- 8. 验证数据完整性
-- ============================================

-- SELECT 'Data Verification' AS info;

-- SELECT
--     'Users' AS table_name,
--     COUNT(*) AS record_count
-- FROM users
-- UNION ALL
-- SELECT
--     'Products' AS table_name,
--     COUNT(*) AS record_count
-- FROM products
-- UNION ALL
-- SELECT
--     'Orders' AS table_name,
--     COUNT(*) AS record_count
-- FROM orders
-- UNION ALL
-- SELECT
--     'Big Table' AS table_name,
--     COUNT(*) AS record_count
-- FROM big_table
-- UNION ALL
-- SELECT
--     'Products Array' AS table_name,
--     COUNT(*) AS record_count
-- FROM products_array
-- UNION ALL
-- SELECT
--     'Logs' AS table_name,
--     COUNT(*) AS record_count
-- FROM logs;

-- SELECT 'Sample Data' AS info;
-- SELECT * FROM users ORDER BY id LIMIT 3;
-- SELECT * FROM products ORDER BY price DESC LIMIT 3;
-- SELECT * FROM orders ORDER BY order_date DESC LIMIT 3;

-- SELECT 'Index Information' AS info;
-- SELECT
--     schemaname || '.' || relname AS table_name,
--     indexname AS index_name,
--     indexdef AS index_definition
-- FROM pg_indexes
-- WHERE schemaname = 'public'
-- ORDER BY relname, indexname;

-- ============================================
-- 9. 性能基准测试
-- ============================================

-- 9.1 启用查询统计
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- SELECT pg_stat_statements_reset();

-- 9.2 测试不同索引的使用情况
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE phone = '13812345678';
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = 1 AND status = 'completed';
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM big_table WHERE user_id = 1 ORDER BY created_at DESC LIMIT 10;

-- 9.3 查看慢查询
-- SELECT * FROM query_stats ORDER BY mean_time DESC LIMIT 10;

-- ============================================
-- 10. 清理函数
-- ============================================

-- 10.1 清理所有测试数据
-- DROP TABLE IF EXISTS logs CASCADE;
-- DROP TABLE IF EXISTS products_array CASCADE;
-- DROP TABLE IF EXISTS big_table CASCADE;
-- DROP FUNCTION IF EXISTS get_user_count_by_age_range(INT, INT);
-- DROP FUNCTION IF EXISTS get_top_users(INT);
-- DROP VIEW IF EXISTS query_stats;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS products CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- 10.2 清理pg_stat_statements统计
-- SELECT pg_stat_statements_reset();

-- SELECT 'Cleanup Complete' AS info;
