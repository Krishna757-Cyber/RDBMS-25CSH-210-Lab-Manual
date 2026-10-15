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