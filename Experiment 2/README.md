# Experiment 2 — Relational Schema and MySQL Implementation

## Aim

Convert the Experiment 1 Indian e-commerce ER diagram into a relational schema and implement it in MySQL. Write complete `CREATE TABLE` statements using primary keys, foreign keys, `NOT NULL`, `UNIQUE`, `ON DELETE CASCADE` and `ON DELETE SET NULL`. Insert sample data and demonstrate referential integrity violations.

## Schema

The database `dbms_lab` contains nine tables: `Customer`, `Address`, `Seller`, `Category`, `Product`, `Orders`, `Order_Item`, `Payment` and `Delivery`.

`Orders` is used instead of `Order` because `ORDER` is a reserved keyword in MySQL. `Order_Item` is a weak entity, so it uses the composite primary key `(OrderID, ItemSeq)`. `Payment` and `Delivery` each reference `Order_Item (OrderID, ItemSeq)` and enforce one row per order item through a `UNIQUE (OrderID, ItemSeq)` constraint.

| Table | Primary Key | Foreign Keys | Other Constraints |
|-------|-------------|--------------|-------------------|
| `Customer` | `CustomerID` | — | `Email` NOT NULL UNIQUE, `CreatedAt` DEFAULT CURRENT_TIMESTAMP |
| `Address` | `AddressID` | `CustomerID` → Customer | `IsDefault` DEFAULT FALSE, Street/City/State/Pincode NOT NULL |
| `Seller` | `SellerID` | — | `Email` UNIQUE, `GSTIN` UNIQUE |
| `Category` | `CategoryID` | `ParentCategoryID` → Category | Self-referencing (category hierarchy) |
| `Product` | `ProductID` | `SellerID` → Seller, `CategoryID` → Category | `CHECK (Price >= 0)`, `CHECK (StockQty >= 0)` |
| `Orders` | `OrderID` | `CustomerID` → Customer | `CHECK (TotalAmt >= 0)` |
| `Order_Item` | `(OrderID, ItemSeq)` | `OrderID` → Orders, `ProductID` → Product | `CHECK (Quantity > 0)`, `UnitPrice >= 0`, `Subtotal >= 0` |
| `Payment` | `PID` | `(OrderID, ItemSeq)` → Order_Item | `UNIQUE (OrderID, ItemSeq)`, `CHECK (Amt >= 0)` |
| `Delivery` | `DID` | `(OrderID, ItemSeq)` → Order_Item | `UNIQUE (OrderID, ItemSeq)` |

### Referential Actions

| Foreign Key | Parent | Action |
|-------------|--------|:------:|
| `Address.CustomerID` | Customer | `ON DELETE CASCADE` |
| `Product.SellerID` | Seller | `ON DELETE CASCADE` |
| `Product.CategoryID` | Category | Default (`RESTRICT`) |
| `Category.ParentCategoryID` | Category | `ON DELETE SET NULL` |
| `Orders.CustomerID` | Customer | `ON DELETE CASCADE` |
| `Order_Item.OrderID` | Orders | `ON DELETE CASCADE` |
| `Order_Item.ProductID` | Product | `ON DELETE SET NULL` |
| `Payment (OrderID, ItemSeq)` | Order_Item | `ON DELETE CASCADE` |
| `Delivery (OrderID, ItemSeq)` | Order_Item | `ON DELETE CASCADE` |

## Artifact and Code

The original handwritten experiment is the reference for this README. It contains the relational schema, the full DDL (`Source Code`), the sample `INSERT` statements, the `SELECT` queries with their outputs, and the referential integrity demonstrations.

The source script follows this order:

1. `DROP DATABASE IF EXISTS dbms_lab;`, then `CREATE DATABASE dbms_lab;` and `USE dbms_lab;`
2. Create tables in dependency order: Customer, Address, Seller, Category, Product, Orders, Order_Item, Payment, Delivery
3. `SHOW TABLES;` to display all 9 tables
4. Insert sample data, parents first, then children

## Sample Data

| Table | Rows | Details |
|-------|:----:|---------|
| Customer | 2 | `C001`, `C002` |
| Address | 3 | `A001` (C001), `A002` (C002), `A003` (C002) |
| Seller | 2 | `S001` Tech World, `S002` Smart Store |
| Category | 3 | `CAT01` (root), `CAT02` and `CAT03` (children of CAT01) |
| Product | 3 | Laptop (₹65,000), Smartphone (₹30,000), Wireless Mouse (₹800) |
| Orders | 2 | `0001` (₹65,800, Confirmed), `0002` (₹30,000, Shipped) |
| Order_Item | 3 | `0001-1`, `0001-2`, `0002-1` |
| Payment | 3 | `PM001`, `PM002`, `PM003` (UPI / Card) |
| Delivery | 3 | `D001`, `D002` (Delivered), `D003` (In Transit) |

## Output and Expected Behavior

- `SHOW TABLES;` lists 9 tables: address, category, customer, delivery, order_item, orders, payment, product, seller.
- `SELECT` on Customer returns 2 rows (C001, C002).
- Orders joined with Customer returns 2 rows: order `0001` with total ₹65,800.00 and order `0002` with total ₹30,000.00.
- Order_Item left-joined with Product returns 3 rows: Laptop, Wireless Mouse and Smartphone.

### Referential Integrity Violations

| # | Statement | Result | Reason |
|:-:|-----------|--------|--------|
| 1 | Insert an `Order_Item` for non-existing order `'0999'` | `ERROR 1452 (23000)`: Cannot add or update a child row: a foreign key constraint fails | `OrderID = '0999'` does not exist in `Orders` |
| 2 | Insert a `Product` with non-existing seller `'S999'` | `ERROR 1452 (23000)`: Cannot add or update a child row: a foreign key constraint fails | `SellerID = 'S999'` does not exist in `Seller` |

### `ON DELETE SET NULL` Demonstration

```sql
DELETE FROM Category WHERE CategoryID = 'CAT01';
SELECT CategoryID, ParentCategoryID FROM Category;
```

| CategoryID | ParentCategoryID |
|------------|------------------|
| CAT02 | NULL |
| CAT03 | NULL |

The child categories remain, but their `ParentCategoryID` becomes `NULL`.

### `ON DELETE CASCADE` Demonstration

```sql
DELETE FROM Customer WHERE CustomerID = 'C001';
```

Because of `ON DELETE CASCADE`, the related records are deleted automatically:

```
Customer C001
   ↓
Address A001
   ↓
Orders 0001
   ↓
Order_Item 0001-1, 0001-2
   ↓
Payments PM001, PM002
   ↓
Deliveries D001, D002
```

Verify the result:

```sql
SELECT * FROM Orders WHERE CustomerID = 'C001';
```

Output: `Empty set`. Customer `C002` and order `0002` are not affected.

## Run

1. Open MySQL Workbench or any MySQL client.
2. Execute the Source Code statements in order: database, tables, then sample data.
3. Run the `SELECT` queries and the two failing `INSERT` statements to see the foreign key errors.
4. Run the two deletion tests (`SET NULL` and `CASCADE`) **separately and last**, because they modify the sample data. Re-run the full script to restore the data.

## Key Concepts Demonstrated

| Concept | Where used |
|---------|-----------|
| Primary key | Every table |
| Composite primary key | `Order_Item (OrderID, ItemSeq)` (weak entity) |
| Foreign key | Address, Product, Orders, Order_Item, Payment, Delivery, Category |
| `NOT NULL` | Mandatory columns such as names, dates, amounts |
| `UNIQUE` | Customer/Seller email, GSTIN, Payment and Delivery per order item |
| `CHECK` | Price, stock, quantity, amounts must not be negative |
| `ON DELETE CASCADE` | Customer → Address/Orders → Order_Item → Payment/Delivery |
| `ON DELETE SET NULL` | Category hierarchy, `Order_Item.ProductID` |
| Self-referencing FK | `Category.ParentCategoryID` |

## Author

Experiment 2 — Database Management Systems (DBMS) Lab
