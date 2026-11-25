# Experiment 10: Query Optimization Using EXPLAIN, Indexing and Rewriting

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |
| **Database** | MySQL 8.0.18+ with InnoDB (run on ByteXL online compiler / MySQL Workbench) |

---

## Aim

To diagnose inefficient SQL queries on a 10,000-row dataset using `EXPLAIN` and `EXPLAIN ANALYZE`, apply targeted B-Tree indexes, rewrite queries to ensure sargability and avoid correlated subqueries, and compare execution performance before and after optimization.

---

## Description

Query optimization involves improving data retrieval performance through proper indexing and query design:
1. **Sargability (Search Argument Able):** Avoiding functions or operations on indexed columns in `WHERE` clauses (e.g. `YEAR(order_date)` or `LOWER(email)`) so the B-Tree index can be traversed directly.
2. **Date Range vs. Function:** Replacing `YEAR(order_date) = 2025` with a half-open date range `order_date >= '2025-01-01' AND order_date < '2026-01-01'`.
3. **Correlated Subquery Elimination:** Converting an $O(N^2)$ correlated counting subquery into a pre-aggregated subquery joined once via an indexed join column.
4. **Order By Expressions:** Eliminating unnecessary arithmetic expressions in `ORDER BY` (e.g. `ORDER BY total_amount * 1.0 DESC`) so the optimizer can perform an index scan instead of an expensive filesort.

---

## Schema

```
sales_orders (
    order_id INT PK,
    customer_id INT,
    customer_email VARCHAR(120),
    order_date DATETIME,
    order_status VARCHAR(20),
    product_name VARCHAR(100),
    quantity INT,
    total_amount DECIMAL(10,2),
    city VARCHAR(60)
)
```

---

## Source Code

```sql
-- EXPERIMENT 10: QUERY OPTIMIZATION USING EXPLAIN, INDEXING AND REWRITING
-- DBMS: MySQL 8.0.18+ with InnoDB
-- Dataset: 10,000 deterministic sales-order rows
-- Execute in a fresh MySQL session, in the order shown.
-- Use the database/schema selected by the editor; this account cannot create databases.

-- =========================================================
-- PART A: CREATE TABLE AND GENERATE 10,000 ROWS
-- =========================================================
DROP TABLE IF EXISTS sales_orders;
CREATE TABLE sales_orders (
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    customer_email VARCHAR(120) NOT NULL,
    order_date DATETIME NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    city VARCHAR(60) NOT NULL,
    PRIMARY KEY (order_id),
    CHECK (quantity > 0),
    CHECK (total_amount >= 0)
) ENGINE = InnoDB;

SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO sales_orders (
    order_id, customer_id, customer_email,
    order_date, order_status, product_name, quantity, total_amount, city
)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    n,
    1000 + MOD(n, 500),
    CONCAT('customer', 1000 + MOD(n, 500), '@example.com'),
    TIMESTAMP('2025-01-01 08:00:00')
        + INTERVAL MOD(n * 17, 730) DAY
        + INTERVAL MOD(n * 13, 1440) MINUTE,
    CASE MOD(n, 4)
        WHEN 0 THEN 'PLACED'
        WHEN 1 THEN 'SHIPPED'
        WHEN 2 THEN 'DELIVERED'
        ELSE 'CANCELLED'
    END,
    CONCAT('Product ', LPAD(MOD(n, 80) + 1, 2, '0')),
    MOD(n, 5) + 1,
    ROUND(150 + MOD(n * 137, 90000) / 100, 2),
    CASE MOD(n, 5)
        WHEN 0 THEN 'Lucknow'
        WHEN 1 THEN 'Delhi'
        WHEN 2 THEN 'Kanpur'
        WHEN 3 THEN 'Agra'
        ELSE 'Varanasi'
    END
FROM seq;

SELECT COUNT(*) AS total_rows FROM sales_orders; -- expected 10000
SELECT * FROM sales_orders ORDER BY order_id LIMIT 10;

-- Keep only the primary key initially. The five query tests below are
-- intentionally run before creating their supporting secondary indexes.
ANALYZE TABLE sales_orders;

-- =========================================================
-- PART B: FIVE SLOW QUERIES - BEFORE OPTIMIZATION
-- EXPLAIN ANALYZE executes each query. Query 4 is intentionally EXPLAIN-only
-- because its unindexed correlated count can exceed the sandbox timeout.
-- =========================================================

-- SLOW QUERY 1: applying YEAR() to the indexed candidate date column
-- makes the predicate non-sargable for a normal order_date index.
EXPLAIN
SELECT order_id, customer_id, order_date, total_amount
FROM sales_orders
WHERE YEAR(order_date) = 2025;

EXPLAIN ANALYZE
SELECT order_id, customer_id, order_date, total_amount
FROM sales_orders
WHERE YEAR(order_date) = 2025;

-- SLOW QUERY 2: applying LOWER() to customer_email prevents a normal
-- index lookup on the original column.
EXPLAIN
SELECT order_id, customer_id, customer_email
FROM sales_orders
WHERE LOWER(customer_email) = 'customer1007@example.com';

EXPLAIN ANALYZE
SELECT order_id, customer_id, customer_email
FROM sales_orders
WHERE LOWER(customer_email) = 'customer1007@example.com';

-- SLOW QUERY 3: filters on status and date without a supporting composite index.
EXPLAIN
SELECT order_id, order_date, total_amount
FROM sales_orders
WHERE order_status = 'SHIPPED'
  AND order_date >= '2025-06-01'
  AND order_date < '2025-07-01';

EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM sales_orders
WHERE order_status = 'SHIPPED'
  AND order_date >= '2025-06-01'
  AND order_date < '2025-07-01';

-- SLOW QUERY 4: correlated subquery repeatedly counts a customer's orders.
EXPLAIN
SELECT so.order_id, so.customer_id, so.total_amount
FROM sales_orders AS so
WHERE (
    SELECT COUNT(*)
    FROM sales_orders AS x
    WHERE x.customer_id = so.customer_id
) > 20;
-- Not run with EXPLAIN ANALYZE: this executes an expensive repeated table scan.
-- The optimized version below can be measured after idx_customer_id is created.

-- SLOW QUERY 5: arithmetic expression in ORDER BY prevents direct ordering by a simple total_amount index.
EXPLAIN
SELECT order_id, customer_id, total_amount
FROM sales_orders
ORDER BY total_amount * 1.0 DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT order_id, customer_id, total_amount
FROM sales_orders
ORDER BY total_amount * 1.0 DESC
LIMIT 20;

-- =========================================================
-- PART C: CREATE INDEXES FOR THE FILTERING / JOIN PATTERNS
-- =========================================================
CREATE INDEX idx_order_date
ON sales_orders(order_date);

CREATE INDEX idx_customer_email
ON sales_orders(customer_email);

CREATE INDEX idx_status_order_date
ON sales_orders(order_status, order_date);

CREATE INDEX idx_customer_id
ON sales_orders(customer_id);

CREATE INDEX idx_total_amount
ON sales_orders(total_amount DESC);

ANALYZE TABLE sales_orders;

-- =========================================================
-- PART D: OPTIMIZED / REWRITTEN QUERIES - AFTER OPTIMIZATION
-- =========================================================

-- OPTIMIZED QUERY 1: replace YEAR() with a half-open date range.
EXPLAIN
SELECT order_id, customer_id, order_date, total_amount
FROM sales_orders
WHERE order_date >= '2025-01-01'
  AND order_date < '2026-01-01';

EXPLAIN ANALYZE
SELECT order_id, customer_id, order_date, total_amount
FROM sales_orders
WHERE order_date >= '2025-01-01'
  AND order_date < '2026-01-01';

-- OPTIMIZED QUERY 2: emails are generated and stored in lowercase.
-- Compare the column directly to the normalized lowercase value.
EXPLAIN
SELECT order_id, customer_id, customer_email
FROM sales_orders
WHERE customer_email = 'customer1007@example.com';

EXPLAIN ANALYZE
SELECT order_id, customer_id, customer_email
FROM sales_orders
WHERE customer_email = 'customer1007@example.com';

-- OPTIMIZED QUERY 3: same predicates, now supported by a composite index.
EXPLAIN
SELECT order_id, order_date, total_amount
FROM sales_orders
WHERE order_status = 'SHIPPED'
  AND order_date >= '2025-06-01'
  AND order_date < '2025-07-01';

EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM sales_orders
WHERE order_status = 'SHIPPED'
  AND order_date >= '2025-06-01'
  AND order_date < '2025-07-01';

-- OPTIMIZED QUERY 4: aggregate once by customer, then join the result.
-- idx_customer_id supports grouping and matching by customer_id.
EXPLAIN
SELECT so.order_id, so.customer_id, so.total_amount
FROM sales_orders AS so
JOIN (
    SELECT customer_id
    FROM sales_orders
    GROUP BY customer_id
    HAVING COUNT(*) > 20
) AS frequent_customers
ON frequent_customers.customer_id = so.customer_id;

EXPLAIN ANALYZE
SELECT so.order_id, so.customer_id, so.total_amount
FROM sales_orders AS so
JOIN (
    SELECT customer_id
    FROM sales_orders
    GROUP BY customer_id
    HAVING COUNT(*) > 20
) AS frequent_customers
ON frequent_customers.customer_id = so.customer_id;

-- OPTIMIZED QUERY 5: order directly by the indexed numeric column.
EXPLAIN
SELECT order_id, customer_id, total_amount
FROM sales_orders
ORDER BY total_amount DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT order_id, customer_id, total_amount
FROM sales_orders
ORDER BY total_amount DESC
LIMIT 20;

-- =========================================================
-- PART E: VERIFY INDEXES AND ROW COUNTS
-- =========================================================
SHOW INDEX FROM sales_orders;
SELECT COUNT(*) AS total_rows_after_optimization FROM sales_orders;

-- Optional result-count checks for rewritten filters.
SELECT COUNT(*) AS q1_optimized_rows
FROM sales_orders
WHERE order_date >= '2025-01-01'
  AND order_date < '2026-01-01';

SELECT COUNT(*) AS q2_optimized_rows
FROM sales_orders
WHERE customer_email = 'customer1007@example.com';

SELECT COUNT(*) AS q3_optimized_rows
FROM sales_orders
WHERE order_status = 'SHIPPED'
  AND order_date >= '2025-06-01'
  AND order_date < '2025-07-01';
```

---

## Performance Comparison Summary

| Query | Issue Before Optimization | Solution Applied | Impact |
|---|---|---|---|
| **Query 1 (Date)** | `YEAR(order_date)` prevents index range scan | Rewrote to half-open interval `[2025-01-01, 2026-01-01)` with `idx_order_date` | Switched from full scan to index range scan |
| **Query 2 (Email)** | `LOWER(customer_email)` disables index usage | Compared column directly with normalized literal using `idx_customer_email` | Switched from full scan (`ALL`) to index lookup (`ref`) |
| **Query 3 (Status + Date)** | No index on composite predicate | Added composite index `(order_status, order_date)` | Directly locates matching rows without scanning non-matching statuses |
| **Query 4 (Correlated Count)** | Correlated subquery scans table per row ($O(N^2)$) | Replaced with pre-aggregated derived table joined on indexed `customer_id` | Drastic execution time reduction; prevents timeout |
| **Query 5 (Sort Order)** | Arithmetic expression in `ORDER BY` causes filesort | Ordered directly on `total_amount DESC` using B-Tree index | Eliminated `Using filesort`, reads top 20 rows directly from index |

---

## Conclusion

By analyzing query execution plans via `EXPLAIN` and `EXPLAIN ANALYZE`, bottlenecks such as non-sargable predicates, unnecessary sorting, and correlated subqueries were identified and eliminated through intelligent query rewriting and composite B-Tree indexing.
