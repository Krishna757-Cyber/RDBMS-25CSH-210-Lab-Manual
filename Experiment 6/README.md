# Experiment 6: Stored Procedure & Triggers

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |
| **Database** | MySQL 8.0+ (run on ByteXL online compiler) |

---

## Aim

To create a stored procedure `transfer_employee(emp_id, new_dept_id)` with validation and error handling, and to implement database triggers for salary validation and audit logging.

---

## Description

A **stored procedure** is a precompiled collection of SQL statements that can be executed as a single unit. In this experiment, a stored procedure named `transfer_employee` is used to transfer an employee from one department to another. The procedure accepts an employee ID and a new department ID as parameters.

The procedure validates whether the employee exists and whether the destination department exists before performing the transfer. Transaction control and error handling are used so that the operation is rolled back if an error occurs.

**Triggers** are special database programs that execute automatically when specified events occur on a table. A salary validation trigger is implemented to prevent invalid or negative salary values. An audit trigger records salary changes in a separate audit table so that changes can be tracked.

The experiment also tests valid transfers, invalid employee IDs, invalid department IDs, invalid salary values, and salary update auditing.

> The SQL uses **MySQL 8.0 or later**.

### Key Concepts

| Concept | Explanation |
|---|---|
| Stored procedure | Named, reusable block of SQL stored in the database and run with `CALL` |
| `START TRANSACTION` / `COMMIT` / `ROLLBACK` | Group statements so they succeed or fail together |
| `DECLARE EXIT HANDLER FOR SQLEXCEPTION` | Runs cleanup code (here `ROLLBACK`) and exits the procedure when an error occurs |
| `SIGNAL SQLSTATE '45000'` | Raises a custom error with a user-defined message |
| `RESIGNAL` | Re-raises the original error after the handler finishes, so the caller still sees it |
| `BEFORE INSERT/UPDATE` trigger | Runs before the row is written; used to validate and reject bad data |
| `AFTER UPDATE` trigger | Runs after the row is changed; used for audit logging |
| `OLD` / `NEW` | Row values before and after the change |
| `<=>` | NULL-safe equality operator, so `NOT (OLD.salary <=> NEW.salary)` detects any real change, including changes involving `NULL` |

---

## Schema

```
department (department_id PK, department_name)
     |1
     |            N
     +----< employee (employee_id PK, employee_name, department_id FK, salary)

salary_audit (audit_id PK AUTO_INCREMENT, employee_id, old_salary, new_salary, changed_at)
```

### Sample Data

**department**

| department_id | department_name |
|---|---|
| 1 | IT |
| 2 | HR |
| 3 | Finance |

**employee**

| employee_id | employee_name | department_id | salary |
|---|---|---|---|
| 101 | Amit | 1 | 90000.00 |
| 102 | Neha | 1 | 65000.00 |
| 103 | Rahul | 2 | 60000.00 |
| 104 | Priya | 3 | 80000.00 |

---

## Source Code

```sql
-- =============================================
-- STEP 1: CREATE DATABASE
-- =============================================

CREATE DATABASE IF NOT EXISTS DBMS_LAB;
USE DBMS_LAB;


-- =============================================
-- STEP 2: DROP OLD OBJECTS
-- =============================================

DROP TRIGGER IF EXISTS salary_audit_after_update;
DROP TRIGGER IF EXISTS validate_salary_before_update;
DROP TRIGGER IF EXISTS validate_salary_before_insert;

DROP PROCEDURE IF EXISTS transfer_employee;

DROP TABLE IF EXISTS salary_audit;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS department;


-- =============================================
-- STEP 3: CREATE DEPARTMENT TABLE
-- =============================================

CREATE TABLE department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL
) ENGINE = InnoDB;


-- =============================================
-- STEP 4: CREATE EMPLOYEE TABLE
-- =============================================

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department_id INT,
    salary DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id)
        REFERENCES department(department_id)
) ENGINE = InnoDB;


-- =============================================
-- STEP 5: INSERT SAMPLE DEPARTMENTS
-- =============================================

INSERT INTO department
    (department_id, department_name)
VALUES
    (1, 'IT'),
    (2, 'HR'),
    (3, 'Finance');


-- =============================================
-- STEP 6: INSERT SAMPLE EMPLOYEES
-- =============================================

INSERT INTO employee
    (employee_id, employee_name, department_id, salary)
VALUES
    (101, 'Amit', 1, 90000.00),
    (102, 'Neha', 1, 65000.00),
    (103, 'Rahul', 2, 60000.00),
    (104, 'Priya', 3, 80000.00);


-- =============================================
-- STEP 7: CREATE SALARY AUDIT TABLE
-- =============================================

CREATE TABLE salary_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;


-- =============================================
-- STEP 8: STORED PROCEDURE
-- EMPLOYEE TRANSFER WITH VALIDATION
-- =============================================

DELIMITER //

CREATE PROCEDURE transfer_employee(
    IN emp_id INT,
    IN new_dept_id INT
)
BEGIN
    DECLARE employee_count INT DEFAULT 0;
    DECLARE department_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validate employee

    SELECT COUNT(*)
    INTO employee_count
    FROM employee
    WHERE employee_id = emp_id;

    IF employee_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employee does not exist';
    END IF;

    -- Validate department

    SELECT COUNT(*)
    INTO department_count
    FROM department
    WHERE department_id = new_dept_id;

    IF department_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Department does not exist';
    END IF;

    -- Transfer employee

    UPDATE employee
    SET department_id = new_dept_id
    WHERE employee_id = emp_id;

    COMMIT;

    SELECT 'Employee transferred successfully.' AS message;
END //

DELIMITER ;


-- =============================================
-- STEP 9: TEST VALID TRANSFER
-- =============================================

CALL transfer_employee(102, 2);

SELECT *
FROM employee
WHERE employee_id = 102;


-- =============================================
-- STEP 10: TEST INVALID EMPLOYEE
-- This call should return an error
-- =============================================

CALL transfer_employee(999, 2);


-- =============================================
-- STEP 11: TEST INVALID DEPARTMENT
-- This call should return an error
-- =============================================

CALL transfer_employee(102, 99);


-- =============================================
-- STEP 12: TRIGGER FOR SALARY VALIDATION
-- BEFORE INSERT
-- =============================================

DELIMITER //

CREATE TRIGGER validate_salary_before_insert
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Salary must be greater than zero';
    END IF;
END //

DELIMITER ;


-- =============================================
-- STEP 13: TRIGGER FOR SALARY VALIDATION
-- BEFORE UPDATE
-- =============================================

DELIMITER //

CREATE TRIGGER validate_salary_before_update
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Salary must be greater than zero';
    END IF;
END //

DELIMITER ;


-- =============================================
-- STEP 14: TRIGGER FOR SALARY AUDIT
-- AFTER UPDATE
-- =============================================

DELIMITER //

CREATE TRIGGER salary_audit_after_update
AFTER UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NOT (OLD.salary <=> NEW.salary) THEN
        INSERT INTO salary_audit
            (employee_id, old_salary, new_salary)
        VALUES
            (OLD.employee_id, OLD.salary, NEW.salary);
    END IF;
END //

DELIMITER ;


-- =============================================
-- STEP 15: TEST INVALID SALARY
-- Expected: ERROR, salary remains unchanged
-- =============================================

UPDATE employee
SET salary = -5000
WHERE employee_id = 101;


-- =============================================
-- STEP 16: TEST VALID SALARY UPDATE
-- Expected: salary becomes 95000
-- =============================================

UPDATE employee
SET salary = 95000
WHERE employee_id = 101;


-- =============================================
-- STEP 17: DISPLAY AUDIT RECORDS
-- =============================================

SELECT *
FROM salary_audit;


-- =============================================
-- STEP 18: DISPLAY FINAL EMPLOYEE DATA
-- =============================================

SELECT *
FROM employee;
```

---

## Output

> Expected results for the final source code above. Steps 10, 11 and 15 are *meant* to raise errors. Some online compilers (including ByteXL) stop executing at the first error, so run those statements separately from the rest if you want to capture every output.

### Screenshot 1: Successful Employee Transfer (Step 9)

`CALL transfer_employee(102, 2);`

| message |
|---|
| Employee transferred successfully. |

`SELECT * FROM employee WHERE employee_id = 102;` shows Neha moved from IT (1) to HR (2):

| employee_id | employee_name | department_id | salary |
|---|---|---|---|
| 102 | Neha | 2 | 65000.00 |

### Screenshot 2: Invalid Employee / Department Validation (Steps 10 and 11)

`CALL transfer_employee(999, 2);`

```
ERROR 1644 (45000): Employee does not exist
```

`CALL transfer_employee(102, 99);`

```
ERROR 1644 (45000): Department does not exist
```

In both cases the transaction is rolled back and no data changes.

### Screenshot 3: Salary Validation Trigger (Step 15)

`UPDATE employee SET salary = -5000 WHERE employee_id = 101;`

```
ERROR 1644 (45000): Salary must be greater than zero
```

The `BEFORE UPDATE` trigger rejects the statement, so Amit's salary stays at 90000.00 and no audit row is written.

### Screenshot 4: Salary Audit Log (Steps 16 and 17)

`UPDATE employee SET salary = 95000 WHERE employee_id = 101;` succeeds, and the `AFTER UPDATE` trigger logs the change:

| audit_id | employee_id | old_salary | new_salary | changed_at |
|---|---|---|---|---|
| 1 | 101 | 90000.00 | 95000.00 | *(time of execution)* |

The earlier department transfer does not create an audit row because the salary did not change.

### Final Employee Data (Step 18)

| employee_id | employee_name | department_id | salary |
|---|---|---|---|
| 101 | Amit | 1 | 95000.00 |
| 102 | Neha | 2 | 65000.00 |
| 103 | Rahul | 2 | 60000.00 |
| 104 | Priya | 3 | 80000.00 |

> **Note on the earlier PDF screenshots:** they were taken with an earlier version of the procedure whose error handler displayed *"Transfer failed. Transaction rolled back."* instead of re-raising the error. The final code uses `RESIGNAL`, so the caller now sees the actual error message (for example *Employee does not exist*), which is more informative.

---

## Explanation

**Stored procedure `transfer_employee`**

1. Starts a transaction.
2. Counts matching rows to check the employee exists; raises `'Employee does not exist'` otherwise.
3. Checks the destination department exists; raises `'Department does not exist'` otherwise.
4. Updates the employee's `department_id` and commits.
5. If any error occurs, the `EXIT HANDLER` rolls back the transaction and `RESIGNAL` passes the error to the caller.

**Triggers**

| Trigger | Event | Purpose |
|---|---|---|
| `validate_salary_before_insert` | BEFORE INSERT on `employee` | Rejects new rows with `NULL` or non-positive salary |
| `validate_salary_before_update` | BEFORE UPDATE on `employee` | Rejects updates that set salary to `NULL` or non-positive |
| `salary_audit_after_update` | AFTER UPDATE on `employee` | Inserts `(employee_id, old_salary, new_salary)` into `salary_audit` only when the salary actually changed |

---

## How to Run

1. Open MySQL 8.0 or later (MySQL Workbench, CLI, or ByteXL online compiler).
2. Copy the SQL from the [Source Code](#source-code) section and run it. Clients that need it should have `DELIMITER` support enabled.
3. The script drops and recreates all objects, so it is safe to re-run.

---

## Conclusion

The experiment showed how a stored procedure with validation, transaction control and error handling can safely transfer an employee between departments. Triggers enforced data integrity by rejecting invalid salaries, and an audit trigger automatically recorded every salary change in a separate table for tracking.
