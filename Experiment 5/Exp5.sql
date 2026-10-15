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