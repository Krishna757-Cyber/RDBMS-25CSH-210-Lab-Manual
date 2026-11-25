-- EXPERIMENT 8: BANKING TRANSACTIONS AND ISOLATION LEVELS
-- MySQL 8.0+ with InnoDB.
-- This script uses the database selected by the environment; it does not
-- create or switch databases, which may require privileges you do not have.
-- Run setup/transaction sections in one session. Concurrency examples in
-- Parts F-I require two independent sessions and are intentionally comments.

-- =========================
-- PART A: DATABASE SETUP
-- =========================
DROP TABLE IF EXISTS transaction_log;
DROP TABLE IF EXISTS bank_account;

CREATE TABLE bank_account (
    account_id   INT PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    balance      DECIMAL(12, 2) NOT NULL,
    CHECK (balance >= 0)
) ENGINE = InnoDB;

CREATE TABLE transaction_log (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT NOT NULL,
    to_account   INT NOT NULL,
    amount       DECIMAL(12, 2) NOT NULL,
    note         VARCHAR(150),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

INSERT INTO bank_account (account_id, account_name, balance)
VALUES
    (101, 'Aarav Sharma', 10000.00),
    (102, 'Diya Verma',   7000.00),
    (103, 'Kabir Singh',  5000.00);

SELECT * FROM bank_account ORDER BY account_id;

-- ======================================
-- PART B: SUCCESSFUL TRANSFER + COMMIT
-- Expected: account 101 decreases by 1000 and account 102 increases by 1000.
-- ======================================
START TRANSACTION;
UPDATE bank_account
SET balance = balance - 1000.00
WHERE account_id = 101 AND balance >= 1000.00;
SELECT ROW_COUNT() AS debit_rows_affected;

UPDATE bank_account
SET balance = balance + 1000.00
WHERE account_id = 102;

INSERT INTO transaction_log (from_account, to_account, amount, note)
VALUES (101, 102, 1000.00, 'Successful transfer');
COMMIT;

SELECT * FROM bank_account ORDER BY account_id;
SELECT * FROM transaction_log ORDER BY log_id;

-- ==========================================
-- PART C: FULL ROLLBACK AFTER PARTIAL FAILURE
-- ==========================================
-- Simulate a missing destination account, then roll back the debit.
START TRANSACTION;
UPDATE bank_account
SET balance = balance - 500.00
WHERE account_id = 101 AND balance >= 500.00;
SELECT ROW_COUNT() AS debit_rows_affected;

UPDATE bank_account
SET balance = balance + 500.00
WHERE account_id = 999;
SELECT ROW_COUNT() AS credit_rows_affected; -- Expected: 0

ROLLBACK; -- Balances must be unchanged by the failed transfer.
SELECT * FROM bank_account ORDER BY account_id;

-- ======================================
-- PART D: SAVEPOINT AND PARTIAL ROLLBACK
-- ======================================
-- Undo the failed credit attempt, then credit a valid destination account.
START TRANSACTION;
UPDATE bank_account
SET balance = balance - 300.00
WHERE account_id = 101 AND balance >= 300.00;
SAVEPOINT after_debit;

UPDATE bank_account
SET balance = balance + 300.00
WHERE account_id = 999;

ROLLBACK TO SAVEPOINT after_debit;

UPDATE bank_account
SET balance = balance + 300.00
WHERE account_id = 103;

INSERT INTO transaction_log (from_account, to_account, amount, note)
VALUES (101, 103, 300.00, 'Transfer completed after savepoint rollback');

RELEASE SAVEPOINT after_debit;
COMMIT;

SELECT * FROM bank_account ORDER BY account_id;
SELECT * FROM transaction_log ORDER BY log_id;

-- ======================================
-- PART E: ISOLATION LEVELS
-- ======================================
-- Isolation levels are per session. This applies to the next transaction.
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- Other supported levels:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- ==============================================================
-- PART F: DIRTY READ DEMONSTRATION (TWO SESSIONS REQUIRED)
-- ==============================================================
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- UPDATE bank_account SET balance = 12000.00 WHERE account_id = 101;
-- Do NOT COMMIT or ROLLBACK yet.
--
-- SESSION B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM bank_account WHERE account_id = 101;
-- Expected: B can see A's uncommitted value (12000.00), a dirty read.
-- ROLLBACK;
--
-- SESSION A:
-- ROLLBACK;
-- The original committed balance is restored.

-- ==============================================================
-- PART G: NON-REPEATABLE READ DEMONSTRATION (TWO SESSIONS)
-- ==============================================================
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM bank_account WHERE account_id = 102;
-- Keep this transaction open.
--
-- SESSION B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- UPDATE bank_account SET balance = balance + 250.00 WHERE account_id = 102;
-- COMMIT;
--
-- SESSION A:
-- SELECT balance FROM bank_account WHERE account_id = 102;
-- Expected: the second read is 250.00 higher.
-- COMMIT;

-- ==============================================================
-- PART H: PHANTOM READ DEMONSTRATION (TWO SESSIONS)
-- ==============================================================
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- SELECT account_id, balance FROM bank_account
-- WHERE balance >= 6000.00 ORDER BY account_id;
-- Keep this transaction open.
--
-- SESSION B:
-- START TRANSACTION;
-- INSERT INTO bank_account (account_id, account_name, balance)
-- VALUES (104, 'Ishita Rao', 8500.00);
-- COMMIT;
--
-- SESSION A:
-- SELECT account_id, balance FROM bank_account
-- WHERE balance >= 6000.00 ORDER BY account_id;
-- Expected: account 104 appears in the second result.
-- COMMIT;
--
-- After both sessions finish, remove the demonstration row if it exists:
-- DELETE FROM bank_account WHERE account_id = 104;

-- ==============================================================
-- PART I: REPEATABLE READ COMPARISON (TWO SESSIONS)
-- ==============================================================
-- SESSION A:
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- START TRANSACTION;
-- SELECT balance FROM bank_account WHERE account_id = 102;
--
-- SESSION B:
-- UPDATE bank_account SET balance = balance + 100.00 WHERE account_id = 102;
-- COMMIT;
--
-- SESSION A:
-- SELECT balance FROM bank_account WHERE account_id = 102;
-- Expected for ordinary non-locking SELECTs: the same snapshot value as the
-- first SELECT. Commit A; a new transaction can see B's update.
--
-- InnoDB REPEATABLE READ uses a consistent snapshot for ordinary non-locking
-- SELECTs. Locking reads (SELECT ... FOR UPDATE) use current read behavior.

-- ======================================
-- PART J: FINAL VERIFICATION
-- ======================================
SELECT * FROM bank_account ORDER BY account_id;
SELECT * FROM transaction_log ORDER BY log_id;
SELECT COUNT(*) AS accounts_with_negative_balance
FROM bank_account
WHERE balance < 0; -- Expected: 0
