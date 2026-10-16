# Experiment 4: SQL Joins, Subqueries, Set Operations & EXPLAIN

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |
| **Database** | MySQL (run on ByteXL online compiler) |

---

## Aim

To write and execute SQL queries using the Employee schema with INNER JOIN, LEFT JOIN, self-join, 3-way join, correlated subqueries, EXISTS, simulated INTERSECT and EXCEPT, and to compare execution plans using EXPLAIN.

---

## Description

This experiment demonstrates different SQL techniques for retrieving and comparing data from the Employee schema.

- **INNER JOIN** returns only the records that have a match in both tables.
- **LEFT JOIN** returns all records from the left table along with the matching records from the right table (unmatched rows get `NULL`).
- **Self-join** is used when a table is joined with itself, such as when employees are related to their managers.
- **3-way join** combines three related tables in a single query.
- **Correlated subquery** is a subquery that executes with reference to values from the outer query (re-evaluated per outer row).
- **EXISTS / NOT EXISTS** checks whether a related record exists.
- **Simulated INTERSECT and EXCEPT** can be achieved using `EXISTS` / `NOT EXISTS` because MySQL does not provide these set operators in older versions.
- **EXPLAIN** shows the query execution plan and helps understand how the database engine processes a query.

---

## Schema

```
Department (dept_id PK, dept_name)
     |1
     |            N
     +----< Employee (emp_id PK, emp_name, dept_id FK, manager_id FK -> Employee.emp_id, salary)
     |
     |            N
     +----< Project  (project_id PK, project_name, dept_id FK)
```

| Table | Columns | Constraints |
|---|---|---|
| **Department** | `dept_id`, `dept_name` | PK on `dept_id`; `dept_name` NOT NULL |
| **Employee** | `emp_id`, `emp_name`, `dept_id`, `manager_id`, `salary` | PK on `emp_id`; FK `dept_id` -> Department; self-referencing FK `manager_id` -> Employee; `emp_name`, `salary` NOT NULL |
| **Project** | `project_id`, `project_name`, `dept_id` | PK on `project_id`; FK `dept_id` -> Department; `project_name` NOT NULL |

### Sample Data

**Department**

| dept_id | dept_name |
|---|---|
| 1 | IT |
| 2 | HR |
| 3 | Finance |
| 4 | Marketing |
| 5 | Legal |

**Employee**

| emp_id | emp_name | dept_id | manager_id | salary |
|---|---|---|---|---|
| 101 | Raj | 1 | NULL | 80000.00 |
| 102 | Aman | 1 | 101 | 60000.00 |
| 103 | Priya | 2 | NULL | 70000.00 |
| 104 | Rohan | 2 | 103 | 50000.00 |
| 105 | Neha | 3 | NULL | 75000.00 |
| 106 | Karan | 3 | 105 | 55000.00 |
| 107 | Simran | 4 | NULL | 65000.00 |
| 108 | Arjun | 1 | 101 | 55000.00 |
| 109 | Ishaan | 5 | NULL | 52000.00 |
| 110 | Meera | NULL | NULL | 48000.00 |

**Project**

| project_id | project_name | dept_id |
|---|---|---|
| 201 | Website Development | 1 |
| 202 | Mobile Application | 1 |
| 203 | Recruitment System | 2 |
| 204 | Financial Analysis | 3 |
| 205 | Marketing Campaign | 4 |

> **Note on the data:** *Ishaan* (Legal, no project) and *Meera* (no department) were added so that LEFT JOIN, NOT EXISTS (simulated EXCEPT) and the 3-way join show meaningful differences from the INNER JOIN / EXISTS results.

---

## Source Code

```sql
-- =====================================================
-- STEP 1: CREATE DATABASE
-- =====================================================

CREATE DATABASE IF NOT EXISTS DBMS_LAB;
USE DBMS_LAB;


-- =====================================================
-- STEP 2: REMOVE OLD TABLES IF THEY EXIST
-- =====================================================

DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Department;


-- =====================================================
-- STEP 3: CREATE DEPARTMENT TABLE
-- =====================================================

CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
) ENGINE = InnoDB;


-- =====================================================
-- STEP 4: CREATE EMPLOYEE TABLE
-- =====================================================

CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50) NOT NULL,
    dept_id INT,
    manager_id INT,
    salary DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_employee_department
        FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id),

    CONSTRAINT fk_employee_manager
        FOREIGN KEY (manager_id)
        REFERENCES Employee(emp_id)
) ENGINE = InnoDB;


-- =====================================================
-- STEP 5: CREATE PROJECT TABLE
-- =====================================================

CREATE TABLE Project (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id INT,

    CONSTRAINT fk_project_department
        FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id)
) ENGINE = InnoDB;


-- =====================================================
-- STEP 6: INSERT DATA INTO DEPARTMENT
-- =====================================================

INSERT INTO Department (dept_id, dept_name)
VALUES
(1, 'IT'),
(2, 'HR'),
(3, 'Finance'),
(4, 'Marketing'),
(5, 'Legal');


-- =====================================================
-- STEP 7: INSERT DATA INTO EMPLOYEE
-- =====================================================

INSERT INTO Employee
    (emp_id, emp_name, dept_id, manager_id, salary)
VALUES
(101, 'Raj',     1, NULL, 80000.00),
(102, 'Aman',    1, 101,  60000.00),
(103, 'Priya',   2, NULL, 70000.00),
(104, 'Rohan',   2, 103,  50000.00),
(105, 'Neha',    3, NULL, 75000.00),
(106, 'Karan',   3, 105,  55000.00),
(107, 'Simran',  4, NULL, 65000.00),
(108, 'Arjun',   1, 101,  55000.00),
(109, 'Ishaan',  5, NULL, 52000.00),
(110, 'Meera', NULL, NULL, 48000.00);


-- =====================================================
-- STEP 8: INSERT DATA INTO PROJECT
-- =====================================================

INSERT INTO Project
    (project_id, project_name, dept_id)
VALUES
(201, 'Website Development', 1),
(202, 'Mobile Application',  1),
(203, 'Recruitment System',  2),
(204, 'Financial Analysis',  3),
(205, 'Marketing Campaign',  4);


-- =====================================================
-- STEP 9: DISPLAY TABLE DATA
-- =====================================================

SELECT * FROM Department;

SELECT * FROM Employee;

SELECT * FROM Project;


-- =====================================================
-- 1. INNER JOIN
-- Display employees and their department names
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee e
INNER JOIN Department d
    ON e.dept_id = d.dept_id
ORDER BY e.emp_id;


-- =====================================================
-- 2. LEFT JOIN
-- Display all employees, including those without
-- an assigned department
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee e
LEFT JOIN Department d
    ON e.dept_id = d.dept_id
ORDER BY e.emp_id;


-- =====================================================
-- 3. SELF JOIN
-- Display employees with their respective managers
-- =====================================================

SELECT
    e.emp_name AS employee_name,
    m.emp_name AS manager_name
FROM Employee e
LEFT JOIN Employee m
    ON e.manager_id = m.emp_id
ORDER BY e.emp_id;


-- =====================================================
-- 4. THREE-WAY JOIN
-- Display employee, department and project details
-- =====================================================

SELECT
    e.emp_name,
    d.dept_name,
    p.project_name
FROM Employee e
INNER JOIN Department d
    ON e.dept_id = d.dept_id
INNER JOIN Project p
    ON d.dept_id = p.dept_id
ORDER BY e.emp_id, p.project_id;


-- =====================================================
-- 5. CORRELATED SUBQUERY
-- Display employees earning more than their
-- department's average salary
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.salary
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
)
ORDER BY e.emp_id;


-- =====================================================
-- 6. EXISTS
-- Display employees whose departments have
-- at least one project
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name
FROM Employee e
WHERE EXISTS (
    SELECT 1
    FROM Project p
    WHERE p.dept_id = e.dept_id
)
ORDER BY e.emp_id;


-- =====================================================
-- 7. SIMULATED INTERSECT
-- Find employees who earn at least 60000 AND whose
-- departments have at least one project.
--
-- Set A: Employees earning at least 60000
-- Set B: Employees belonging to departments with projects
-- Result: A INTERSECT B
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name
FROM Employee e
WHERE e.salary >= 60000
  AND EXISTS (
      SELECT 1
      FROM Project p
      WHERE p.dept_id = e.dept_id
  )
ORDER BY e.emp_id;


-- =====================================================
-- 8. SIMULATED EXCEPT
-- Display employees whose departments have no
-- matching project.
--
-- Set A: All employees
-- Set B: Employees belonging to departments with projects
-- Result: A EXCEPT B
-- =====================================================

SELECT
    e.emp_id,
    e.emp_name
FROM Employee e
WHERE NOT EXISTS (
    SELECT 1
    FROM Project p
    WHERE p.dept_id = e.dept_id
)
ORDER BY e.emp_id;


-- =====================================================
-- 9. EXPLAIN: INNER JOIN EXECUTION PLAN
-- =====================================================

EXPLAIN
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee e
INNER JOIN Department d
    ON e.dept_id = d.dept_id;


-- =====================================================
-- 10. EXPLAIN: CORRELATED SUBQUERY EXECUTION PLAN
-- =====================================================

EXPLAIN
SELECT
    e.emp_id,
    e.emp_name,
    e.salary
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
);


-- =====================================================
-- 11. EXPLAIN: EXISTS EXECUTION PLAN
-- =====================================================

EXPLAIN
SELECT
    e.emp_id,
    e.emp_name
FROM Employee e
WHERE EXISTS (
    SELECT 1
    FROM Project p
    WHERE p.dept_id = e.dept_id
);
```

---

## Output

> The outputs below are for the sample data listed above. Run the script in MySQL (e.g. ByteXL) and attach screenshots in the `screenshots/` folder if required.

### Step 9: Table Data

Displayed in the [Sample Data](#sample-data) section above (`SELECT * FROM Department / Employee / Project`).

### 1. INNER JOIN

Employees with a department. *Meera* (no department) is excluded.

| emp_id | emp_name | dept_name |
|---|---|---|
| 101 | Raj | IT |
| 102 | Aman | IT |
| 103 | Priya | HR |
| 104 | Rohan | HR |
| 105 | Neha | Finance |
| 106 | Karan | Finance |
| 107 | Simran | Marketing |
| 108 | Arjun | IT |
| 109 | Ishaan | Legal |

### 2. LEFT JOIN

All employees, including *Meera* whose `dept_name` is `NULL`.

| emp_id | emp_name | dept_name |
|---|---|---|
| 101 | Raj | IT |
| 102 | Aman | IT |
| 103 | Priya | HR |
| 104 | Rohan | HR |
| 105 | Neha | Finance |
| 106 | Karan | Finance |
| 107 | Simran | Marketing |
| 108 | Arjun | IT |
| 109 | Ishaan | Legal |
| 110 | Meera | NULL |

### 3. SELF JOIN (Employee and Manager)

| employee_name | manager_name |
|---|---|
| Raj | NULL |
| Aman | Raj |
| Priya | NULL |
| Rohan | Priya |
| Neha | NULL |
| Karan | Neha |
| Simran | NULL |
| Arjun | Raj |
| Ishaan | NULL |
| Meera | NULL |

### 4. THREE-WAY JOIN

Employees with their department and every project of that department. *Ishaan* (Legal) and *Meera* are excluded since they have no matching project; IT employees appear twice because IT has two projects.

| emp_name | dept_name | project_name |
|---|---|---|
| Raj | IT | Website Development |
| Raj | IT | Mobile Application |
| Aman | IT | Website Development |
| Aman | IT | Mobile Application |
| Priya | HR | Recruitment System |
| Rohan | HR | Recruitment System |
| Neha | Finance | Financial Analysis |
| Karan | Finance | Financial Analysis |
| Simran | Marketing | Marketing Campaign |
| Arjun | IT | Website Development |
| Arjun | IT | Mobile Application |

### 5. CORRELATED SUBQUERY

Department averages: IT = 65000, HR = 60000, Finance = 65000, Marketing = 65000, Legal = 52000. Meera is excluded because comparing with a `NULL` department average yields `NULL`.

| emp_id | emp_name | dept_id | salary |
|---|---|---|---|
| 101 | Raj | 1 | 80000.00 |
| 103 | Priya | 2 | 70000.00 |
| 105 | Neha | 3 | 75000.00 |

### 6. EXISTS

Employees whose department has at least one project.

| emp_id | emp_name |
|---|---|
| 101 | Raj |
| 102 | Aman |
| 103 | Priya |
| 104 | Rohan |
| 105 | Neha |
| 106 | Karan |
| 107 | Simran |
| 108 | Arjun |

### 7. SIMULATED INTERSECT

Salary >= 60000 **AND** department has a project.

| emp_id | emp_name |
|---|---|
| 101 | Raj |
| 102 | Aman |
| 103 | Priya |
| 105 | Neha |
| 107 | Simran |

### 8. SIMULATED EXCEPT

Employees whose department has **no** project (*Ishaan*: Legal has no project; *Meera*: no department).

| emp_id | emp_name |
|---|---|
| 109 | Ishaan |
| 110 | Meera |

### 9. EXPLAIN: INNER JOIN

Result observed on ByteXL (MySQL):

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | e | ALL | NULL | NULL | NULL | NULL | 8 | 100.00 | Using where |
| 1 | SIMPLE | d | eq_ref | PRIMARY | PRIMARY | 4 | sandbox_db.e.dept_id | 1 | 100.00 | NULL |

### 10 & 11. EXPLAIN: Correlated Subquery and EXISTS

Run these two statements in your MySQL environment and paste the plan here. The exact numbers depend on the MySQL version and table statistics.

---

## Execution Plan Analysis

**INNER JOIN plan (Query 9)**

- `Employee (e)` is the driving table, read with `type = ALL`, which is a full table scan (acceptable for such a small table).
- For each employee row, `Department (d)` is accessed with `type = eq_ref` using the `PRIMARY` key. This is the best join access type: exactly one matching row is read per lookup.
- `key_len = 4` confirms that the 4-byte `INT` primary key `dept_id` is used.

**Correlated subquery (Query 10)**

- The inner query depends on `e.dept_id`, so conceptually it is evaluated for each outer row to compute that department's average salary. This can be slower on large tables than a join with a pre-aggregated derived table, though MySQL's optimizer may transform it.

**EXISTS (Query 11)**

- `EXISTS` stops searching as soon as the first matching project is found for a department (semi-join), so it avoids reading all matching rows and does not produce duplicates, unlike a plain join.

| Technique | Behaviour | Typical use |
|---|---|---|
| INNER JOIN | Combines columns of matching rows; can duplicate rows | Need columns from both tables |
| LEFT JOIN | Keeps all left rows; unmatched get NULL | Find missing relationships |
| Correlated subquery | Re-evaluated per outer row | Row vs. group comparisons |
| EXISTS | Boolean check, stops at first match | Existence tests, no duplicates |
| NOT EXISTS | Rows with no match | Simulated EXCEPT / anti-join |

---

## How to Run

1. Open any MySQL client (MySQL Workbench, CLI, or ByteXL online compiler).
2. Copy the SQL from the [Source Code](#source-code) section.
3. Execute the script. It drops and recreates the tables, so it is safe to re-run.

---

## Conclusion

The experiment demonstrated INNER JOIN, LEFT JOIN, self-join and 3-way join to combine related data, along with correlated subqueries and `EXISTS` / `NOT EXISTS` to filter rows based on related records. Simulated INTERSECT and EXCEPT were successfully achieved without direct set operators. Finally, `EXPLAIN` was used to understand how MySQL executes queries, showing primary-key lookups (`eq_ref`) for the join.
