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

-- =========================================================
-- PART G: OPTIONAL REPEATABLE TIMING PROCEDURE
-- =========================================================
-- Run the same SELECT / EXPLAIN ANALYZE several times at each stage.
-- Record actual execution time and actual rows from EXPLAIN ANALYZE.
-- Do not invent or copy timing values: results depend on hardware, cache,
-- MySQL version, data distribution and concurrent server activity.
-- To compare a true no-secondary-index baseline again, drop both indexes:
-- DROP INDEX idx_train_no ON railway_booking;
-- DROP INDEX idx_train_date_status ON railway_booking;
-- ANALYZE TABLE railway_booking;
-- Then repeat the baseline EXPLAIN statements.

-- NOTE:
-- EXPLAIN shows the optimizer's estimated execution plan.
-- EXPLAIN ANALYZE executes the SELECT and reports actual iterator timing
-- and row counts. Timings can vary between runs. An index is not guaranteed
-- to improve every query; compare the chosen access type, key, estimated rows,
-- actual rows, and measured time rather than assuming a fixed speedup.
