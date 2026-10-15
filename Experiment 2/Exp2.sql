-- EXPERIMENT 2
-- ER Diagram to Relational Schema

DROP DATABASE IF EXISTS dbms_lab;
CREATE DATABASE dbms_lab;
USE dbms_lab;

-- 1. CUSTOMER TABLE
CREATE TABLE Customer (
    CustomerID VARCHAR(10) PRIMARY KEY,
    FirstName VARCHAR(30) NOT NULL,
    LastName VARCHAR(30) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    DOB DATE,
    Gender VARCHAR(10),
    PhoneNo VARCHAR(15),
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. ADDRESS TABLE
CREATE TABLE Address (
    AddressID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    AddressType VARCHAR(20) NOT NULL,
    IsDefault BOOLEAN NOT NULL DEFAULT FALSE,
    Street VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50) NOT NULL,
    Pincode VARCHAR(10) NOT NULL,

    CONSTRAINT fk_address_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE CASCADE
);

-- 3. SELLER TABLE
CREATE TABLE Seller (
    SellerID VARCHAR(10) PRIMARY KEY,
    SellerName VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    GSTIN VARCHAR(20) NOT NULL UNIQUE
);

-- 4. CATEGORY TABLE
CREATE TABLE Category (
    CategoryID VARCHAR(10) PRIMARY KEY,
    ParentCategoryID VARCHAR(10) NULL,

    CONSTRAINT fk_category_parent
        FOREIGN KEY (ParentCategoryID)
        REFERENCES Category(CategoryID)
        ON DELETE SET NULL
);

-- 5. PRODUCT TABLE
CREATE TABLE Product (
    ProductID VARCHAR(10) PRIMARY KEY,
    SellerID VARCHAR(10) NOT NULL,
    CategoryID VARCHAR(10) NOT NULL,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    StockQty INT NOT NULL DEFAULT 0 CHECK (StockQty >= 0),
    Description VARCHAR(255),

    CONSTRAINT fk_product_seller
        FOREIGN KEY (SellerID)
        REFERENCES Seller(SellerID)
        ON DELETE CASCADE,

    CONSTRAINT fk_product_category
        FOREIGN KEY (CategoryID)
        REFERENCES Category(CategoryID)
);

-- 6. ORDERS TABLE
-- ORDERS is used instead of ORDER because ORDER is a MySQL keyword.
CREATE TABLE Orders (
    OrderID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmt DECIMAL(12,2) NOT NULL CHECK (TotalAmt >= 0),
    OrderStatus VARCHAR(20) NOT NULL,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE CASCADE
);

-- 7. ORDER_ITEM TABLE
-- Composite primary key because OrderItem is a weak entity.
CREATE TABLE Order_Item (
    OrderID VARCHAR(10) NOT NULL,
    ItemSeq INT NOT NULL,
    ProductID VARCHAR(10) NULL,
    AddressID VARCHAR(10) NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    Subtotal DECIMAL(12,2) NOT NULL CHECK (Subtotal >= 0),

    PRIMARY KEY (OrderID, ItemSeq),

    CONSTRAINT fk_orderitem_order
        FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID)
        ON DELETE CASCADE,

    CONSTRAINT fk_orderitem_product
        FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID)
        ON DELETE SET NULL,

    CONSTRAINT fk_orderitem_address
        FOREIGN KEY (AddressID)
        REFERENCES Address(AddressID)
        ON DELETE SET NULL
);

-- 8. PAYMENT TABLE
CREATE TABLE Payment (
    PID VARCHAR(10) PRIMARY KEY,
    OrderID VARCHAR(10) NOT NULL,
    ItemSeq INT NOT NULL,
    PMode VARCHAR(20) NOT NULL,
    Amt DECIMAL(12,2) NOT NULL CHECK (Amt >= 0),
    PStatus VARCHAR(20) NOT NULL,
    PDate DATE NOT NULL,

    CONSTRAINT uq_payment_order_item
        UNIQUE (OrderID, ItemSeq),

    CONSTRAINT fk_payment_orderitem
        FOREIGN KEY (OrderID, ItemSeq)
        REFERENCES Order_Item(OrderID, ItemSeq)
        ON DELETE CASCADE
);

-- 9. DELIVERY TABLE
CREATE TABLE Delivery (
    DID VARCHAR(10) PRIMARY KEY,
    OrderID VARCHAR(10) NOT NULL,
    ItemSeq INT NOT NULL,
    CourierName VARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL,
    EstDate DATE,
    DeliveryDate DATE,

    CONSTRAINT uq_delivery_order_item
        UNIQUE (OrderID, ItemSeq),

    CONSTRAINT fk_delivery_orderitem
        FOREIGN KEY (OrderID, ItemSeq)
        REFERENCES Order_Item(OrderID, ItemSeq)
        ON DELETE CASCADE
);

-- Display all created tables
SHOW TABLES;