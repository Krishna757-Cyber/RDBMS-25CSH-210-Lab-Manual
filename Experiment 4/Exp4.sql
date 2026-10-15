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