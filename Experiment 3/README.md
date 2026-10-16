# Experiment 3 — Employee, Department, and Project Queries

## Aim

To create an Employee–Department–Project database schema, insert at least 30 employees across 5 departments and 8 projects, and execute SQL queries demonstrating selection, projection, aggregation, `GROUP BY`, `HAVING`, `CASE` expressions, and `ORDER BY`.

## Description

This experiment demonstrates the use of SQL for managing and analyzing data stored in an Employee–Department–Project schema. The database contains five departments, eight projects, and thirty employees distributed among the departments and projects.

The experiment covers these SQL operations:

- **Selection** using `WHERE`
- **Projection** using `SELECT` with specific columns
- **Aggregation** using `COUNT`, `AVG` and `SUM`
- **Grouping** records using `GROUP BY`
- **Filtering grouped results** using `HAVING`
- **Conditional classification** using `CASE` expressions
- **Sorting** query results using `ORDER BY`
- **Joins** across three tables for a combined report

The schema uses primary keys and foreign keys to maintain relationships between departments, projects and employees. The queries generate useful reports such as department-wise employee counts, average salaries, project assignments, salary classifications, and departments satisfying specified conditions.

## Schema

`Department` is the parent of `Project`; both `Department` and `Project` are referenced by `Employee`.

| Table | Primary Key | Foreign Keys | Columns |
|-------|-------------|--------------|---------|
| `Department` | `dept_id` | — | `dept_name` (NOT NULL), `location` |
| `Project` | `project_id` | `dept_id` → Department | `project_name` (NOT NULL), `budget` |
| `Employee` | `emp_id` | `dept_id` → Department, `project_id` → Project | `emp_name` (NOT NULL), `email`, `salary`, `hire_date` |

### Sample Data

| Table | Rows | Details |
|-------|:----:|---------|
| Department | 5 | Computer Science, Human Resources, Finance, Marketing, Operations |
| Project | 8 | IDs 101–108 (AI Research, Web Development, Recruitment Portal, Financial Analytics, Digital Marketing, Inventory System, Cloud Migration, Business Automation) |
| Employee | 30 | IDs 1001–1030, six employees in each department |

## Requirements

- MySQL 8.0 or later (or any online MySQL compiler, for example ByteXL).
- Run the SQL script in order. It creates/replaces the `DBMS_LAB` sample tables and inserts the complete dataset before running the ten queries.

## Code

The complete source:

```sql
-- Experiment 3: Employee-Department-Project queries
-- MySQL 8.0+
CREATE DATABASE IF NOT EXISTS DBMS_LAB;
USE DBMS_LAB;

DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS Department;

-- Create Department table
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

-- Create Project table
CREATE TABLE Project (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

-- Create Employee table
CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    salary DECIMAL(10,2),
    hire_date DATE,
    dept_id INT,
    project_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
);

-- Insert 5 departments
INSERT INTO Department VALUES
(1, 'Computer Science', 'Block A'),
(2, 'Human Resources', 'Block B'),
(3, 'Finance', 'Block C'),
(4, 'Marketing', 'Block D'),
(5, 'Operations', 'Block E');

-- Insert 8 projects
INSERT INTO Project VALUES
(101, 'AI Research', 500000.00, 1),
(102, 'Web Development', 350000.00, 1),
(103, 'Recruitment Portal', 180000.00, 2),
(104, 'Financial Analytics', 450000.00, 3),
(105, 'Digital Marketing', 300000.00, 4),
(106, 'Inventory System', 250000.00, 5),
(107, 'Cloud Migration', 600000.00, 1),
(108, 'Business Automation', 400000.00, 5);

-- Insert 30 employees
INSERT INTO Employee VALUES
(1001, 'Aarav Sharma', 'aarav@company.com', 65000, '2022-01-15', 1, 101),
(1002, 'Riya Verma', 'riya@company.com', 72000, '2021-03-20', 1, 102),
(1003, 'Arjun Singh', 'arjun@company.com', 58000, '2023-02-10', 1, 101),
(1004, 'Neha Gupta', 'neha@company.com', 81000, '2020-06-18', 1, 107),
(1005, 'Kabir Mehta', 'kabir@company.com', 69000, '2022-08-12', 1, 102),
(1006, 'Ananya Rao', 'ananya@company.com', 76000, '2021-11-05', 1, 107),
(1007, 'Rahul Kumar', 'rahul@company.com', 48000, '2022-04-11', 2, 103),
(1008, 'Simran Kaur', 'simran@company.com', 52000, '2023-01-25', 2, 103),
(1009, 'Vikram Joshi', 'vikram@company.com', 55000, '2021-09-17', 2, 103),
(1010, 'Pooja Nair', 'pooja@company.com', 61000, '2020-12-01', 2, 103),
(1011, 'Karan Malhotra', 'karan@company.com', 50000, '2022-07-22', 2, 103),
(1012, 'Ishita Jain', 'ishita@company.com', 57000, '2023-05-15', 2, 103),
(1013, 'Aditya Patel', 'aditya@company.com', 68000, '2021-02-14', 3, 104),
(1014, 'Meera Shah', 'meera@company.com', 75000, '2020-10-19', 3, 104),
(1015, 'Rohan Das', 'rohan@company.com', 63000, '2022-03-08', 3, 104),
(1016, 'Sneha Iyer', 'sneha@company.com', 71000, '2021-07-13', 3, 104),
(1017, 'Manish Yadav', 'manish@company.com', 59000, '2023-04-20', 3, 104),
(1018, 'Tanya Kapoor', 'tanya@company.com', 82000, '2019-11-30', 3, 104),
(1019, 'Nikhil Bansal', 'nikhil@company.com', 54000, '2022-02-21', 4, 105),
(1020, 'Kritika Sethi', 'kritika@company.com', 62000, '2021-05-16', 4, 105),
(1021, 'Yash Thakur', 'yash@company.com', 57000, '2023-03-11', 4, 105),
(1022, 'Aditi Roy', 'aditi@company.com', 66000, '2020-08-09', 4, 105),
(1023, 'Mohit Arora', 'mohit@company.com', 59000, '2022-10-14', 4, 105),
(1024, 'Diya Khanna', 'diya@company.com', 73000, '2021-12-18', 4, 105),
(1025, 'Sahil Verma', 'sahil@company.com', 56000, '2022-01-07', 5, 106),
(1026, 'Muskan Singh', 'muskan@company.com', 64000, '2020-04-23', 5, 108),
(1027, 'Harsh Vardhan', 'harsh@company.com', 61000, '2021-06-30', 5, 106),
(1028, 'Nisha Sharma', 'nisha@company.com', 70000, '2019-09-12', 5, 108),
(1029, 'Dev Agarwal', 'dev@company.com', 53000, '2023-02-28', 5, 106),
(1030, 'Ira Saxena', 'ira@company.com', 78000, '2020-11-16', 5, 108);

-- 1. Selection: display employees with salary greater than 70000
SELECT *
FROM Employee
WHERE salary > 70000;

-- 2. Projection: display employee names and salaries
SELECT emp_name, salary
FROM Employee;

-- 3. Aggregation: count employees and calculate average salary
SELECT COUNT(*) AS total_employees,
       AVG(salary) AS average_salary
FROM Employee;

-- 4. GROUP BY: department-wise employee count and average salary
SELECT dept_id,
       COUNT(*) AS employee_count,
       AVG(salary) AS average_salary
FROM Employee
GROUP BY dept_id;

-- 5. HAVING: departments having more than 5 employees
SELECT dept_id,
       COUNT(*) AS employee_count
FROM Employee
GROUP BY dept_id
HAVING COUNT(*) > 5;

-- 6. CASE expression: classify employees according to salary
SELECT emp_name,
       salary,
       CASE
           WHEN salary >= 75000 THEN 'High Salary'
           WHEN salary >= 60000 THEN 'Medium Salary'
           ELSE 'Low Salary'
       END AS salary_category
FROM Employee;

-- 7. ORDER BY: display employees in descending order of salary
SELECT emp_name, salary
FROM Employee
ORDER BY salary DESC;

-- 8. Department-wise total salary
SELECT dept_id,
       SUM(salary) AS total_salary
FROM Employee
GROUP BY dept_id
ORDER BY total_salary DESC;

-- 9. Project-wise employee count
SELECT project_id,
       COUNT(*) AS employee_count
FROM Employee
GROUP BY project_id
ORDER BY employee_count DESC;

-- 10. Display employees with department and project details
SELECT e.emp_name,
       d.dept_name,
       p.project_name,
       e.salary
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
JOIN Project p ON e.project_id = p.project_id
ORDER BY e.salary DESC;
```

## Output

Results from the included dataset (the PDF contains the screenshots of each query run in the SQL editor):

| # | Query | Result |
|:-:|-------|--------|
| 1 | Selection (`salary > 70000`) | 8 employee rows |
| 2 | Projection | 30 employee-name and salary rows |
| 3 | Aggregate | 30 employees; average salary = 63,833.33 |
| 4 | Department `GROUP BY` | 5 rows; 6 employees in each department |
| 5 | `HAVING COUNT(*) > 5` | All 5 departments (6 employees each) |
| 6 | Salary `CASE` | 5 High, 13 Medium and 12 Low Salary rows |
| 7 | Salary descending | 30 rows; highest is Tanya Kapoor (82,000), lowest is Rahul Kumar (48,000) |
| 8 | Total salary by department | See table below |
| 9 | Employee count by project | See table below |
| 10 | Three-table report | 30 rows ordered by descending salary |

### Query 1 — Employees with salary > 70000

| emp_id | emp_name | email | salary | hire_date | dept_id | project_id |
|:------:|----------|-------|-------:|-----------|:-------:|:----------:|
| 1002 | Riya Verma | riya@company.com | 72000.00 | 2021-03-20 | 1 | 102 |
| 1004 | Neha Gupta | neha@company.com | 81000.00 | 2020-06-18 | 1 | 107 |
| 1006 | Ananya Rao | ananya@company.com | 76000.00 | 2021-11-05 | 1 | 107 |
| 1014 | Meera Shah | meera@company.com | 75000.00 | 2020-10-19 | 3 | 104 |
| 1016 | Sneha Iyer | sneha@company.com | 71000.00 | 2021-07-13 | 3 | 104 |
| 1018 | Tanya Kapoor | tanya@company.com | 82000.00 | 2019-11-30 | 3 | 104 |
| 1024 | Diya Khanna | diya@company.com | 73000.00 | 2021-12-18 | 4 | 105 |
| 1030 | Ira Saxena | ira@company.com | 78000.00 | 2020-11-16 | 5 | 108 |

### Query 3 — Aggregation

| total_employees | average_salary |
|:---------------:|---------------:|
| 30 | 63833.333333 |

### Query 4 — Department-wise count and average salary

| dept_id | employee_count | average_salary |
|:-------:|:--------------:|---------------:|
| 1 | 6 | 70166.666667 |
| 2 | 6 | 53833.333333 |
| 3 | 6 | 69666.666667 |
| 4 | 6 | 61833.333333 |
| 5 | 6 | 63666.666667 |

### Query 5 — Departments with more than 5 employees

| dept_id | employee_count |
|:-------:|:--------------:|
| 1 | 6 |
| 2 | 6 |
| 3 | 6 |
| 4 | 6 |
| 5 | 6 |

### Query 6 — Salary categories

| Category | Rule | Employees |
|----------|------|:---------:|
| High Salary | salary ≥ 75000 | 5 |
| Medium Salary | 60000 ≤ salary < 75000 | 13 |
| Low Salary | salary < 60000 | 12 |

### Query 8 — Department-wise total salary

| dept_id | Department | total_salary |
|:-------:|------------|-------------:|
| 1 | Computer Science | 421000.00 |
| 3 | Finance | 418000.00 |
| 5 | Operations | 382000.00 |
| 4 | Marketing | 371000.00 |
| 2 | Human Resources | 323000.00 |

### Query 9 — Project-wise employee count

| project_id | Project | employee_count |
|:----------:|---------|:--------------:|
| 103 | Recruitment Portal | 6 |
| 104 | Financial Analytics | 6 |
| 105 | Digital Marketing | 6 |
| 106 | Inventory System | 3 |
| 108 | Business Automation | 3 |
| 101 | AI Research | 2 |
| 102 | Web Development | 2 |
| 107 | Cloud Migration | 2 |

### Query 10 — Employee, department and project report (top 5 rows)

| emp_name | dept_name | project_name | salary |
|----------|-----------|--------------|-------:|
| Tanya Kapoor | Finance | Financial Analytics | 82000.00 |
| Neha Gupta | Computer Science | Cloud Migration | 81000.00 |
| Ira Saxena | Operations | Business Automation | 78000.00 |
| Ananya Rao | Computer Science | Cloud Migration | 76000.00 |
| Meera Shah | Finance | Financial Analytics | 75000.00 |

> Exact row formatting and decimal display can vary by SQL client. Rows with equal counts in Query 9 may appear in a different order.

## Concepts Demonstrated

| Concept | Query |
|---------|:-----:|
| Selection (`WHERE`) | 1 |
| Projection | 2 |
| Aggregate functions (`COUNT`, `AVG`, `SUM`) | 3, 4, 8, 9 |
| `GROUP BY` | 4, 5, 8, 9 |
| `HAVING` | 5 |
| `CASE` expression | 6 |
| `ORDER BY` | 7, 8, 9, 10 |
| `JOIN` on three tables | 10 |

## Author

**Krishna Gopal Rathore**
B.Tech CSE AI&ML-2(A) · Roll No. 25LBCS3190
Database Management Systems (DBMS) Lab — Experiment 3
