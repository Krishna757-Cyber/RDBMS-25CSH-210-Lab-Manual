-- EXPERIMENT 7: NORMALIZATION OF A DENORMALIZED SALES TABLE
-- DBMS: MySQL 8.0+
-- Run this script in a schema/database already selected in the editor.
-- The SQL account may not have permission to create or select databases.

-- 1. Start with a denormalized (UNF) sales structure.
-- Repeating product groups are represented as multiple rows when converted to 1NF.
DROP TABLE IF EXISTS Sales_UNF;
CREATE TABLE Sales_UNF (
    OrderID INT NOT NULL,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    CustomerCity VARCHAR(80) NOT NULL,
    SalespersonID INT NOT NULL,
    SalespersonName VARCHAR(100) NOT NULL,
    ProductID INT NOT NULL,
    ProductName VARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    CHECK (UnitPrice >= 0),
    CHECK (Quantity > 0)
);

INSERT INTO Sales_UNF VALUES
(1001, '2026-10-01', 101, 'Aarav Sharma', 'Lucknow', 11, 'Meera Singh', 501, 'Keyboard', 850.00, 2),
(1001, '2026-10-01', 101, 'Aarav Sharma', 'Lucknow', 11, 'Meera Singh', 502, 'Mouse', 450.00, 1),
(1002, '2026-10-02', 102, 'Diya Verma', 'Kanpur', 12, 'Rohan Gupta', 501, 'Keyboard', 825.00, 1),
(1003, '2026-10-03', 101, 'Aarav Sharma', 'Lucknow', 11, 'Meera Singh', 503, 'Monitor', 7200.00, 1);

-- NOTE: If your SQL editor does not accept letter-prefixed numeric IDs,
-- replace 101/102/11/12/501/502/503 with numeric values.

-- 2. Functional dependencies (FDs) in the 1NF relation:
-- OrderID -> OrderDate, CustomerID, SalespersonID
-- CustomerID -> CustomerName, CustomerCity
-- SalespersonID -> SalespersonName
-- ProductID -> ProductName
-- (OrderID, ProductID) -> UnitPrice, Quantity
--
-- UnitPrice is the actual selling price for that order line. It is NOT
-- assumed to depend only on ProductID, because selling prices can vary
-- between orders (discounts or price changes).

-- 3. Create the 3NF / BCNF decomposition.
-- Each determinant below is a candidate key in its own relation.
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS SalesOrder;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Salesperson;
DROP TABLE IF EXISTS Customer;

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    CustomerCity VARCHAR(80) NOT NULL
);

CREATE TABLE Salesperson (
    SalespersonID INT PRIMARY KEY,
    SalespersonName VARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL
);

CREATE TABLE SalesOrder (
    OrderID INT PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    SalespersonID INT NOT NULL,
    CONSTRAINT fk_order_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT fk_order_salesperson
        FOREIGN KEY (SalespersonID) REFERENCES Salesperson(SalespersonID)
);

CREATE TABLE OrderItem (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT fk_item_order FOREIGN KEY (OrderID) REFERENCES SalesOrder(OrderID),
    CONSTRAINT fk_item_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    CHECK (UnitPrice >= 0),
    CHECK (Quantity > 0)
);

-- 4. Populate the decomposed relations from the original 1NF data.
INSERT INTO Customer (CustomerID, CustomerName, CustomerCity)
SELECT DISTINCT CustomerID, CustomerName, CustomerCity
FROM Sales_UNF;

INSERT INTO Salesperson (SalespersonID, SalespersonName)
SELECT DISTINCT SalespersonID, SalespersonName
FROM Sales_UNF;

INSERT INTO Product (ProductID, ProductName)
SELECT DISTINCT ProductID, ProductName
FROM Sales_UNF;

INSERT INTO SalesOrder (OrderID, OrderDate, CustomerID, SalespersonID)
SELECT DISTINCT OrderID, OrderDate, CustomerID, SalespersonID
FROM Sales_UNF;

INSERT INTO OrderItem (OrderID, ProductID, UnitPrice, Quantity)
SELECT OrderID, ProductID, UnitPrice, Quantity
FROM Sales_UNF;

-- 5. Display all normalized tables.
SELECT * FROM Customer ORDER BY CustomerID;
SELECT * FROM Salesperson ORDER BY SalespersonID;
SELECT * FROM Product ORDER BY ProductID;
SELECT * FROM SalesOrder ORDER BY OrderID;
SELECT * FROM OrderItem ORDER BY OrderID, ProductID;

-- 6. Reconstruct the original relation by joining the decomposed tables.
SELECT
    so.OrderID,
    so.OrderDate,
    c.CustomerID,
    c.CustomerName,
    c.CustomerCity,
    sp.SalespersonID,
    sp.SalespersonName,
    p.ProductID,
    p.ProductName,
    oi.UnitPrice,
    oi.Quantity
FROM SalesOrder AS so
JOIN Customer AS c ON c.CustomerID = so.CustomerID
JOIN Salesperson AS sp ON sp.SalespersonID = so.SalespersonID
JOIN OrderItem AS oi ON oi.OrderID = so.OrderID
JOIN Product AS p ON p.ProductID = oi.ProductID
ORDER BY so.OrderID, p.ProductID;

-- 7. LOSSLESS-JOIN VERIFICATION.
-- A lossless decomposition must reproduce every source row exactly and must not create extra rows.
-- Check both directions using NOT EXISTS.
SELECT
    (SELECT COUNT(*) FROM Sales_UNF) AS source_rows,
    (SELECT COUNT(*) FROM (
        SELECT so.OrderID, oi.ProductID
        FROM SalesOrder so
        JOIN OrderItem oi ON oi.OrderID = so.OrderID
        JOIN Customer c ON c.CustomerID = so.CustomerID
        JOIN Salesperson sp ON sp.SalespersonID = so.SalespersonID
        JOIN Product p ON p.ProductID = oi.ProductID
    ) AS reconstructed) AS reconstructed_rows;

-- Source rows missing from the reconstructed join: expected result = 0.
SELECT COUNT(*) AS missing_source_rows
FROM Sales_UNF s
WHERE NOT EXISTS (
    SELECT 1
    FROM SalesOrder so
    JOIN Customer c ON c.CustomerID = so.CustomerID
    JOIN Salesperson sp ON sp.SalespersonID = so.SalespersonID
    JOIN OrderItem oi ON oi.OrderID = so.OrderID
    JOIN Product p ON p.ProductID = oi.ProductID
    WHERE so.OrderID = s.OrderID
      AND oi.ProductID = s.ProductID
      AND so.OrderDate = s.OrderDate
      AND c.CustomerID = s.CustomerID
      AND c.CustomerName = s.CustomerName
      AND c.CustomerCity = s.CustomerCity
      AND sp.SalespersonID = s.SalespersonID
      AND sp.SalespersonName = s.SalespersonName
      AND p.ProductID = s.ProductID
      AND p.ProductName = s.ProductName
      AND oi.UnitPrice = s.UnitPrice
      AND oi.Quantity = s.Quantity
);

-- Reconstructed rows not present in source: expected result = 0.
SELECT COUNT(*) AS extra_reconstructed_rows
FROM (
    SELECT
        so.OrderID, so.OrderDate,
        c.CustomerID, c.CustomerName,
        c.CustomerCity, sp.SalespersonID, sp.SalespersonName,
        p.ProductID, p.ProductName, oi.UnitPrice, oi.Quantity
    FROM SalesOrder so
    JOIN Customer c ON c.CustomerID = so.CustomerID
    JOIN Salesperson sp ON sp.SalespersonID = so.SalespersonID
    JOIN OrderItem oi ON oi.OrderID = so.OrderID
    JOIN Product p ON p.ProductID = oi.ProductID
) r
WHERE NOT EXISTS (
    SELECT 1 FROM Sales_UNF s
    WHERE s.OrderID = r.OrderID
      AND s.OrderDate = r.OrderDate
      AND s.CustomerID = r.CustomerID
      AND s.CustomerName = r.CustomerName
      AND s.CustomerCity = r.CustomerCity
      AND s.SalespersonID = r.SalespersonID
      AND s.SalespersonName = r.SalespersonName
      AND s.ProductID = r.ProductID
      AND s.ProductName = r.ProductName
      AND s.UnitPrice = r.UnitPrice
      AND s.Quantity = r.Quantity
);

-- 8. DEPENDENCY-PRESERVATION / FD VIOLATION CHECKS.
-- Each query should return zero rows. Primary keys enforce uniqueness
-- for CustomerID, SalespersonID, ProductID, OrderID and (OrderID, ProductID).
-- These checks test the corresponding functional dependencies in data.

-- CustomerID -> CustomerName, CustomerCity
SELECT CustomerID
FROM Customer
GROUP BY CustomerID
HAVING COUNT(DISTINCT CONCAT_WS('|', CustomerName, CustomerCity)) > 1;

-- SalespersonID -> SalespersonName
SELECT SalespersonID
FROM Salesperson
GROUP BY SalespersonID
HAVING COUNT(DISTINCT SalespersonName) > 1;

-- ProductID -> ProductName
SELECT ProductID
FROM Product
GROUP BY ProductID
HAVING COUNT(DISTINCT ProductName) > 1;

-- OrderID -> OrderDate, CustomerID, SalespersonID
SELECT OrderID
FROM SalesOrder
GROUP BY OrderID
HAVING COUNT(DISTINCT CONCAT_WS('|', OrderDate, CustomerID, SalespersonID)) > 1;

-- (OrderID, ProductID) -> UnitPrice, Quantity
SELECT OrderID, ProductID
FROM OrderItem
GROUP BY OrderID, ProductID
HAVING COUNT(DISTINCT CONCAT_WS('|', UnitPrice, Quantity)) > 1;

-- 9. Summary check: expected counts for this sample dataset.
SELECT
    (SELECT COUNT(*) FROM Customer) AS customers,       -- expected 2
    (SELECT COUNT(*) FROM Salesperson) AS salespeople,  -- expected 2
    (SELECT COUNT(*) FROM Product) AS products,         -- expected 3
    (SELECT COUNT(*) FROM SalesOrder) AS orders,        -- expected 3
    (SELECT COUNT(*) FROM OrderItem) AS order_items;    -- expected 4
