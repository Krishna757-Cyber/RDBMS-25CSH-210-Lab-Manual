# Experiment 5: SQL Views, View Updatability & Recursive CTE

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |
| **Database** | MySQL 8.0+ (run on ByteXL online compiler) |

---

## Aim

To create SQL views for department salary summary and employee hierarchy, test the updatability of views, and implement a recursive CTE to display reporting chains.

---

## Description

A SQL **view** is a virtual table based on the result of a `SELECT` query. Views are useful for presenting selected data, simplifying complex queries, and providing controlled access to database information.

In this experiment, two views are created:

- **`department_salary_summary`** groups employees by department and displays the number of employees, total salary, and average salary.
- **`employee_hierarchy`** displays employee details together with their manager information (using a self `LEFT JOIN`).

The **updatability** of a simple single-table view (`employee_basic`) is then tested using an `UPDATE` statement.

A **recursive Common Table Expression (CTE)** is also implemented to display the complete reporting chain of employees. The recursive CTE starts from top-level employees who do not report to another employee (anchor member) and repeatedly joins employees with their managers (recursive member).

> The SQL uses **MySQL 8.0 or later** syntax because recursive CTEs require support for `WITH RECURSIVE`.

### Key Concepts

| Concept | Explanation |
|---|---|
| View | Stored `SELECT` query that behaves like a table; stores no data itself |
| Updatable view | A simple view on a single table (no `GROUP BY`, aggregates, `DISTINCT`, etc.) allows `UPDATE` that passes through to the base table |
| Non-updatable view | Views with aggregates/`GROUP BY` (e.g. `department_salary_summary`) cannot be updated directly |
| Recursive CTE | `WITH RECURSIVE` query made of an anchor member + `UNION ALL` + recursive member that references the CTE itself |
| Self-referencing FK | `manager_id` references `employee(employee_id)`, forming the hierarchy |

---

## Schema

```
department (department_id PK, department_name)
     |1
     |            N
     +----< employee (employee_id PK, employee_name, department_id FK,
                      manager_id FK -> employee.employee_id, salary)
```

### Sample Data

**department**

| department_id | department_name |
|---|---|
| 1 | IT |
| 2 | HR |
| 3 | Finance |

**employee**

| employee_id | employee_name | department_id | manager_id | salary |
|---|---|---|---|---|
| 101 | Amit | 1 | NULL | 90000.00 |
| 102 | Neha | 1 | 101 | 65000.00 |
| 103 | Rahul | 1 | 101 | 60000.00 |
| 104 | Priya | 2 | NULL | 80000.00 |
| 105 | Karan | 2 | 104 | 55000.00 |
| 106 | Riya | 3 | NULL | 85000.00 |
| 107 | Arjun | 3 | 106 | 50000.00 |

---

## Source Code

```sql
-- =====================================================
-- STEP 1: CREATE AND SELECT DATABASE
-- =====================================================

CREATE DATABASE IF NOT EXISTS DBMS_VIEW_LAB;
USE DBMS_VIEW_LAB;


-- =====================================================
-- STEP 2: DROP EXISTING VIEWS AND TABLES
-- =====================================================

DROP VIEW IF EXISTS department_salary_summary;
DROP VIEW IF EXISTS employee_hierarchy;
DROP VIEW IF EXISTS employee_basic;

DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS department;


-- =====================================================
-- STEP 3: CREATE DEPARTMENT TABLE
-- =====================================================

CREATE TABLE department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL
);


-- =====================================================
-- STEP 4: CREATE EMPLOYEE TABLE
-- =====================================================

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department_id INT,
    manager_id INT NULL,
    salary DECIMAL(10,2),

    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id)
        REFERENCES department(department_id),

    CONSTRAINT fk_employee_manager
        FOREIGN KEY (manager_id)
        REFERENCES employee(employee_id)
);


-- =====================================================
-- STEP 5: INSERT SAMPLE DEPARTMENTS
-- =====================================================

INSERT INTO department (department_id, department_name)
VALUES
(1, 'IT'),
(2, 'HR'),
(3, 'Finance');


-- =====================================================
-- STEP 6: INSERT SAMPLE EMPLOYEES
-- =====================================================

INSERT INTO employee
    (employee_id, employee_name, department_id, manager_id, salary)
VALUES
(101, 'Amit',  1, NULL, 90000.00),
(102, 'Neha',  1, 101,  65000.00),
(103, 'Rahul', 1, 101,  60000.00),
(104, 'Priya', 2, NULL, 80000.00),
(105, 'Karan', 2, 104,  55000.00),
(106, 'Riya',  3, NULL, 85000.00),
(107, 'Arjun', 3, 106,  50000.00);


-- =====================================================
-- 1. VIEW FOR DEPARTMENT SALARY SUMMARY
-- =====================================================

CREATE VIEW department_salary_summary AS
SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary
FROM department d
LEFT JOIN employee e
    ON d.department_id = e.department_id
GROUP BY
    d.department_id,
    d.department_name;


-- DISPLAY DEPARTMENT SALARY SUMMARY

SELECT *
FROM department_salary_summary;


-- =====================================================
-- 2. VIEW FOR EMPLOYEE HIERARCHY
-- =====================================================

CREATE VIEW employee_hierarchy AS
SELECT
    e.employee_id,
    e.employee_name,
    e.department_id,
    e.manager_id,
    m.employee_name AS manager_name,
    e.salary
FROM employee e
LEFT JOIN employee m
    ON e.manager_id = m.employee_id;


-- DISPLAY EMPLOYEE HIERARCHY

SELECT *
FROM employee_hierarchy;


-- =====================================================
-- 3. TEST VIEW UPDATABILITY
-- =====================================================

CREATE VIEW employee_basic AS
SELECT
    employee_id,
    employee_name,
    salary
FROM employee;


-- UPDATE SALARY THROUGH THE VIEW

UPDATE employee_basic
SET salary = 70000.00
WHERE employee_id = 102;


-- DISPLAY UPDATED DATA THROUGH THE VIEW

SELECT *
FROM employee_basic
WHERE employee_id = 102;


-- VERIFY THE UPDATE IN THE ORIGINAL TABLE

SELECT *
FROM employee
WHERE employee_id = 102;


-- =====================================================
-- 4. RECURSIVE CTE TO DISPLAY REPORTING CHAINS
-- =====================================================

WITH RECURSIVE reporting_chain AS (

    -- ANCHOR MEMBER: EMPLOYEES WITHOUT MANAGERS

    SELECT
        employee_id,
        employee_name,
        manager_id,
        0 AS hierarchy_level,
        CAST(employee_name AS CHAR(1000)) AS reporting_path
    FROM employee
    WHERE manager_id IS NULL

    UNION ALL

    -- RECURSIVE MEMBER: FIND EMPLOYEES
    -- REPORTING TO EACH EMPLOYEE

    SELECT
        e.employee_id,
        e.employee_name,
        e.manager_id,
        rc.hierarchy_level + 1,
        CONCAT(
            rc.reporting_path,
            ' -> ',
            e.employee_name
        ) AS reporting_path
    FROM employee e
    INNER JOIN reporting_chain rc
        ON e.manager_id = rc.employee_id
)

SELECT
    employee_id,
    employee_name,
    manager_id,
    hierarchy_level,
    reporting_path
FROM reporting_chain
ORDER BY reporting_path;
```

---

## Output

### Screenshot 1: Department Salary Summary

| department_id | department_name | employee_count | total_salary | average_salary |
|---|---|---|---|---|
| 1 | IT | 3 | 215000.00 | 71666.666667 |
| 2 | HR | 2 | 135000.00 | 67500.000000 |
| 3 | Finance | 2 | 135000.00 | 67500.000000 |

### Screenshot 2: Employee Hierarchy

| employee_id | employee_name | department_id | manager_id | manager_name | salary |
|---|---|---|---|---|---|
| 101 | Amit | 1 | NULL | NULL | 90000.00 |
| 102 | Neha | 1 | 101 | Amit | 65000.00 |
| 103 | Rahul | 1 | 101 | Amit | 60000.00 |
| 104 | Priya | 2 | NULL | NULL | 80000.00 |
| 105 | Karan | 2 | 104 | Priya | 55000.00 |
| 106 | Riya | 3 | NULL | NULL | 85000.00 |
| 107 | Arjun | 3 | 106 | Riya | 50000.00 |

### Screenshot 3: View Updatability Test

After `UPDATE employee_basic SET salary = 70000.00 WHERE employee_id = 102;`, the view shows the new salary (Neha: 65000.00 -> 70000.00):

| employee_id | employee_name | salary |
|---|---|---|
| 102 | Neha | 70000.00 |

The change is also reflected in the base `employee` table:

| employee_id | employee_name | department_id | manager_id | salary |
|---|---|---|---|---|
| 102 | Neha | 1 | 101 | 70000.00 |

This confirms that `employee_basic` is an **updatable view**: it is a simple single-table view with no aggregates, `GROUP BY` or `DISTINCT`.

### Screenshot 4: Recursive CTE Reporting Chain

| employee_id | employee_name | manager_id | hierarchy_level | reporting_path |
|---|---|---|---|---|
| 101 | Amit | NULL | 0 | Amit |
| 102 | Neha | 101 | 1 | Amit -> Neha |
| 103 | Rahul | 101 | 1 | Amit -> Rahul |
| 104 | Priya | NULL | 0 | Priya |
| 105 | Karan | 104 | 1 | Priya -> Karan |
| 106 | Riya | NULL | 0 | Riya |
| 107 | Arjun | 106 | 1 | Riya -> Arjun |

> Screenshots from the ByteXL run can be added under a `screenshots/` folder if required for submission.

---

## Explanation

**1. `department_salary_summary`**
A `LEFT JOIN` from `department` ensures every department appears even if it has no employees. `COUNT`, `SUM` and `AVG` aggregate per department. Because it uses aggregation and `GROUP BY`, this view is **not updatable**.

**2. `employee_hierarchy`**
Joins `employee` to itself (`e` = employee, `m` = manager). The `LEFT JOIN` keeps top-level employees (Amit, Priya, Riya) whose `manager_name` is `NULL`.

**3. `employee_basic` (updatability)**
Selecting a subset of columns from one table keeps a one-to-one mapping between view rows and table rows, so MySQL lets the `UPDATE` pass through to `employee`.

**4. Recursive CTE**

1. **Anchor member** selects employees with `manager_id IS NULL` (level 0).
2. **Recursive member** joins `employee` with the CTE itself on `e.manager_id = rc.employee_id`, increasing `hierarchy_level` by 1 and appending the name to `reporting_path`.
3. The recursion ends when no more employees report to anyone in the previous iteration.
4. `CAST(... AS CHAR(1000))` gives the path column a fixed type wide enough for the concatenated chain.

---

## How to Run

1. Open MySQL 8.0 or later (MySQL Workbench, CLI, or ByteXL online compiler).
2. Copy the SQL from the [Source Code](#source-code) section and run it.
3. The script drops and recreates the views and tables, so it is safe to re-run.

---

## Conclusion

The experiment demonstrated creating views for aggregated salary data and manager hierarchy, showed that a simple single-table view is updatable while changes pass through to the base table, and used a recursive CTE to display the full reporting chain starting from top-level employees.
