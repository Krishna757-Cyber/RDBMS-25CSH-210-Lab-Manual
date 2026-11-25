# Experiment 9: Railway Booking Indexing and Query Benchmarking

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |
| **Database** | MySQL 8.0.18+ with InnoDB (run on ByteXL online compiler / MySQL Workbench) |

---

## Aim

To evaluate database indexing techniques on a dataset of 5,000 deterministic railway booking records by comparing query execution plans and iterator execution metrics using `EXPLAIN` and `EXPLAIN ANALYZE` across unindexed, single-column indexed, and composite indexed states.

---

## Description

Indexes are specialized data structures (typically B+ Trees in InnoDB) that enable the database engine to locate specific rows significantly faster than scanning the entire table.

- **Full Table Scan (`ALL`):** The storage engine reads every row in the table, which causes high I/O cost as data volume scales.
- **Single-Column Index:** Created on a single column (e.g. `train_no`). Optimizes queries with equality or range conditions on that column.
- **Composite Index:** Created across multiple columns (e.g. `(train_no, journey_date, booking_status)`). It supports multi-column filtering and adheres to the **leftmost prefix rule** (can satisfy queries filtering on `train_no`, or `train_no + journey_date`, or all three).
- **`EXPLAIN`:** Displays the optimizer's estimated execution plan (access type, possible keys, chosen key, rows examined).
- **`EXPLAIN ANALYZE`:** Actually executes the query and measures precise iterator execution timings, startup/total cost, and actual row counts returned.

---

## Schema

```
railway_booking (
    booking_id INT PK,
    pnr_number CHAR(10) UNIQUE,
    passenger_name VARCHAR(80),
    train_no INT,
    train_name VARCHAR(100),
    journey_date DATE,
    source_station CHAR(5),
    destination CHAR(5),
    booking_status VARCHAR(15),
    coach_type VARCHAR(10),
    fare DECIMAL(8,2)
)
```

---

## Source Code

```sql
-- EXPERIMENT 9: RAILWAY BOOKING INDEXING AND QUERY BENCHMARKING
-- DBMS: MySQL 8.0.18+ (InnoDB; EXPLAIN ANALYZE supported)
-- Execute in a fresh MySQL session. Run each benchmark stage in order.

-- =========================================================
-- PART A: CREATE RAILWAY BOOKING TABLE (NO SECONDARY INDEXES)
-- =========================================================
DROP TABLE IF EXISTS railway_booking;
CREATE TABLE railway_booking (
    booking_id INT NOT NULL,
    pnr_number CHAR(10) NOT NULL,
    passenger_name VARCHAR(80) NOT NULL,
    train_no INT NOT NULL,
    train_name VARCHAR(100) NOT NULL,
    journey_date DATE NOT NULL,
    source_station CHAR(5) NOT NULL,
    destination CHAR(5) NOT NULL,
    booking_status VARCHAR(15) NOT NULL,
    coach_type VARCHAR(10) NOT NULL,
    fare DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (booking_id),
    UNIQUE KEY uq_pnr (pnr_number),
    CHECK (fare >= 0)
) ENGINE = InnoDB;

-- The primary key and unique PNR constraint are required integrity indexes.
-- The performance experiment below compares additional secondary indexes.

-- =========================================================
-- PART B: INSERT 5,000 DETERMINISTIC SAMPLE BOOKINGS
-- =========================================================
-- Raise the recursion limit for this session so the CTE can generate 5,000 rows.
SET SESSION cte_max_recursion_depth = 6000;

INSERT INTO railway_booking (
    booking_id, pnr_number, passenger_name, train_no, train_name,
    journey_date, source_station, destination, booking_status, coach_type, fare
)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT
    n AS booking_id,
    LPAD(n, 10, '0') AS pnr_number,
    CONCAT('Passenger ', n) AS passenger_name,
    12001 + MOD(n, 100) AS train_no,
    CONCAT('Express ', 12001 + MOD(n, 100)) AS train_name,
    DATE_ADD('2026-01-01', INTERVAL MOD(n, 365) DAY) AS journey_date,
    CASE MOD(n, 5)
        WHEN 0 THEN 'LKO'
        WHEN 1 THEN 'NDLS'
        WHEN 2 THEN 'CNB'
        WHEN 3 THEN 'BSB'
        ELSE 'AGC'
    END AS source_station,
    CASE MOD(n, 5)
        WHEN 0 THEN 'NDLS'
        WHEN 1 THEN 'LKO'
        WHEN 2 THEN 'BSB'
        WHEN 3 THEN 'AGC'
        ELSE 'CNB'
    END AS destination,
    CASE MOD(n, 3)
        WHEN 0 THEN 'CONFIRMED'
        WHEN 1 THEN 'WAITLIST'
        ELSE 'CANCELLED'
    END AS booking_status,
    CASE MOD(n, 3)
        WHEN 0 THEN 'SL'
        WHEN 1 THEN '3A'
        ELSE '2A'
    END AS coach_type,
    250.00 + MOD(n * 37, 2500) AS fare
FROM seq;

SELECT COUNT(*) AS total_bookings FROM railway_booking; -- expected: 5000
SELECT * FROM railway_booking ORDER BY booking_id LIMIT 10;

-- =========================================================
-- PART C: BASELINE - BEFORE ADDING SECONDARY INDEXES
-- =========================================================
-- Refresh table statistics before measuring.
ANALYZE TABLE railway_booking;

-- Query 1: Find bookings for one train.
EXPLAIN
SELECT booking_id, passenger_name, journey_date, booking_status
FROM railway_booking
WHERE train_no = 12042;

-- Query 2: Find bookings for a train, date and status.
EXPLAIN
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

-- MySQL 8.0.18+: execute for actual iterator timings and row counts.
EXPLAIN ANALYZE
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

-- =========================================================
-- PART D: CREATE A SINGLE-COLUMN INDEX AND RE-TEST
-- =========================================================
CREATE INDEX idx_train_no ON railway_booking(train_no);
ANALYZE TABLE railway_booking;

-- Query 1 should be able to use idx_train_no.
EXPLAIN
SELECT booking_id, passenger_name, journey_date, booking_status
FROM railway_booking
WHERE train_no = 12042;

EXPLAIN ANALYZE
SELECT booking_id, passenger_name, journey_date, booking_status
FROM railway_booking
WHERE train_no = 12042;

-- The composite-filter query is not fully covered by the single-column index.
EXPLAIN
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

EXPLAIN ANALYZE
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

-- =========================================================
-- PART E: CREATE A COMPOSITE INDEX AND RE-TEST
-- =========================================================
CREATE INDEX idx_train_date_status
ON railway_booking(train_no, journey_date, booking_status);
ANALYZE TABLE railway_booking;

-- The composite index can use all three equality predicates.
EXPLAIN
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

EXPLAIN ANALYZE
SELECT booking_id, passenger_name, fare
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';

-- Leftmost-prefix behavior: the composite index can also support train_no
-- filtering, although the optimizer decides which available index is cheapest.
EXPLAIN
SELECT booking_id, passenger_name, journey_date, booking_status
FROM railway_booking
WHERE train_no = 12042;

-- View all indexes created on the table.
SHOW INDEX FROM railway_booking;

-- =========================================================
-- PART F: COMPARE RESULT COUNTS AND VERIFY DATA
-- =========================================================
SELECT COUNT(*) AS total_bookings FROM railway_booking;

SELECT COUNT(*) AS train_query_rows
FROM railway_booking
WHERE train_no = 12042;

SELECT COUNT(*) AS composite_query_rows
FROM railway_booking
WHERE train_no = 12042
  AND journey_date = '2026-03-15'
  AND booking_status = 'CONFIRMED';
```

---

## Expected Output & Execution Plan Comparison

### Baseline (Part C - No Secondary Indexes)
- `type`: `ALL` (Full Table Scan).
- `rows`: ~5,000 scanned for both Query 1 and Query 2.
- High cost and longer execution time reported in `EXPLAIN ANALYZE`.

### With Single-Column Index (`idx_train_no`) (Part D)
- **Query 1:** Changes `type` from `ALL` to `ref` using `idx_train_no`. Rows examined drops from 5000 to ~50.
- **Query 2:** Uses `idx_train_no` for `train_no = 12042`, but still must perform filter operations on `journey_date` and `booking_status` in memory for those 50 rows.

### With Composite Index (`idx_train_date_status`) (Part E)
- **Query 2:** `type` is `ref` using `idx_train_date_status`. `key_len` covers all three columns (`train_no`, `journey_date`, `booking_status`).
- Examined rows match exact matching records directly without residual table filtering.
- Also satisfies Query 1 under leftmost prefix property.

---

## Conclusion

1. Secondary indexes drastically reduce the number of rows read by replacing full table scans (`ALL`) with index ref lookups (`ref`).
2. A composite index tailored to multiple equality filtering attributes provides optimal query plan execution and eliminates secondary filtering overhead.
