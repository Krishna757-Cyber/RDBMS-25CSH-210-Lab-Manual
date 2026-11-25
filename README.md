# RDBMS-Lab

Semester 3 DBMS lab experiments 1–10.

This repository contains the DBMS laboratory experiments in order. Experiments 1 and 2 preserve the supplied PDF files. Experiments 3–10 each have a separate MySQL source file and a detailed experiment README with the aim, explanation, run guidance, source code, and expected output.

| | |
|---|---|
| **Name** | Krishna Gopal Rathore |
| **Class** | B.Tech CSE AI&ML-2(A) |
| **Roll No.** | 25LBCS3190 |
| **Subject** | Database Management Systems (DBMS) Lab |

---

## Experiments

| Experiment | Topic | Files |
|---|---|---|
| 1 | Indian e-commerce ER diagram | [Experiment 1 README](Experiment%201/README.md) · [Original PDF](Experiment%201/Experiment%201%20.pdf) |
| 2 | Relational schema and MySQL constraints | [Experiment 2 README](Experiment%202/README.md) · [Original PDF](Experiment%202/Experiment%202.pdf) · [SQL source](Experiment%202/Exp2.sql) |
| 3 | Employee, department, and project queries | [Experiment 3 README](Experiment%203/README.md) · [Original PDF](Experiment%203/DBMS_Lab_Experiment_3%20Krishna.pdf) · [SQL source](Experiment%203/Exp3.sql) |
| 4 | Joins, subqueries, and query plans | [Experiment 4 README](Experiment%204/README.md) · [Original PDF](Experiment%204/DBMS_Experiment_4_Lab_Krishna.pdf) · [SQL source](Experiment%204/Exp4.sql) |
| 5 | Views and recursive reporting chain | [Experiment 5 README](Experiment%205/README.md) · [Original PDF](Experiment%205/DBMS_Experiment_5_SQL_Views_Krishna.pdf) · [SQL source](Experiment%205/Exp5.sql) |
| 6 | Stored procedure, validation, and audit triggers | [Experiment 6 README](Experiment%206/README.md) · [Original PDF](Experiment%206/DBMS_Experiment_6_Stored_Procedure_Triggers_Krishna.pdf) · [SQL source](Experiment%206/Exp6.sql) |
| 7 | Normalization of a denormalized sales table (1NF to 3NF/BCNF) | [Experiment 7 README](Experiment%207/README.md) · [Original PDF](Experiment%207/DBMS_Experiment_7_Normalization%20KGR.pdf) · [SQL source](Experiment%207/Exp7.sql) |
| 8 | Banking transactions and isolation levels (ACID, Savepoints, Locks) | [Experiment 8 README](Experiment%208/README.md) · [Original PDF](Experiment%208/DBMS_Experiment_8_Transactions_Isolation%20kgr.pdf) · [SQL source](Experiment%208/Exp8.sql) |
| 9 | Railway booking indexing and query benchmarking (EXPLAIN / EXPLAIN ANALYZE) | [Experiment 9 README](Experiment%209/README.md) · [Original PDF](Experiment%209/DBMS_Experiment_9_Railway_Indexing%20kgr.pdf) · [SQL source](Experiment%209/Exp9.sql) |
| 10 | Query optimization using EXPLAIN, indexing and rewriting | [Experiment 10 README](Experiment%2010/README.md) · [Original PDF](Experiment%2010/DBMS_Experiment_10_Query_Optimization%20KGR.pdf) · [SQL source](Experiment%2010/Exp10.sql) |

### Topics at a Glance

| Experiment | Key concepts |
|---|---|
| 1 | Entities, attributes, relationships, cardinality, ER modelling |
| 2 | Relational schema, primary keys, foreign keys, `NOT NULL`, `UNIQUE`, `CHECK` constraints |
| 3 | Employee, department and project tables; data retrieval queries |
| 4 | `INNER JOIN`, `LEFT JOIN`, self-join, 3-way join, correlated subquery, `EXISTS`, simulated `INTERSECT` / `EXCEPT`, `EXPLAIN` |
| 5 | Views, view updatability, recursive CTE (`WITH RECURSIVE`) |
| 6 | Stored procedure with transaction and error handling, `BEFORE` / `AFTER` triggers, salary audit table |
| 7 | Functional dependencies, 1NF to 3NF/BCNF decomposition, lossless-join verification, dependency preservation |
| 8 | ACID properties, `START TRANSACTION`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, transaction isolation levels (Dirty, Non-repeatable, Phantom reads) |
| 9 | B-Tree indexing, single-column vs composite index, leftmost prefix rule, benchmarking with `EXPLAIN` & `EXPLAIN ANALYZE` on 5,000 rows |
| 10 | Query optimization, sargability, date intervals vs `YEAR()`, correlated subquery flattening, avoiding filesorts, benchmarking on 10,000 rows |

---

## Repository Structure

```
RDBMS-Lab/
├── README.md
├── Experiment 1/
│   ├── README.md
│   └── Experiment 1 .pdf
├── Experiment 2/
│   ├── README.md
│   ├── Exp2.sql
│   └── Experiment 2.pdf
├── Experiment 3/
│   ├── README.md
│   ├── DBMS_Lab_Experiment_3 Krishna.pdf
│   └── Exp3.sql
├── Experiment 4/
│   ├── README.md
│   ├── DBMS_Experiment_4_Lab_Krishna.pdf
│   └── Exp4.sql
├── Experiment 5/
│   ├── README.md
│   ├── DBMS_Experiment_5_SQL_Views_Krishna.pdf
│   └── Exp5.sql
├── Experiment 6/
│   ├── README.md
│   ├── DBMS_Experiment_6_Stored_Procedure_Triggers_Krishna.pdf
│   └── Exp6.sql
├── Experiment 7/
│   ├── README.md
│   ├── DBMS_Experiment_7_Normalization KGR.pdf
│   └── Exp7.sql
├── Experiment 8/
│   ├── README.md
│   ├── DBMS_Experiment_8_Transactions_Isolation kgr.pdf
│   └── Exp8.sql
├── Experiment 9/
│   ├── README.md
│   ├── DBMS_Experiment_9_Railway_Indexing kgr.pdf
│   └── Exp9.sql
└── Experiment 10/
    ├── README.md
    ├── DBMS_Experiment_10_Query_Optimization KGR.pdf
    └── Exp10.sql
```

---

## Database Setup

Experiments 2–10 use **MySQL 8.0+** (InnoDB engine). Each script creates or resets its own sample tables, so every script can be re-run safely.

| Experiment | Database used |
|---|---|
| 4 | `DBMS_LAB` |
| 5 | `DBMS_VIEW_LAB` |
| 6 | `DBMS_LAB` |
| 7–10 | Active schema selected by editor / environment |

Run **one experiment script at a time** in a MySQL client.

- Experiment 6 uses a stored procedure and triggers and therefore requires support for the `DELIMITER` client command.
- Experiments 8–10 demonstrate transactions and performance benchmarking (`EXPLAIN` / `EXPLAIN ANALYZE`).
- Experiments 9 and 10 use recursive CTEs (`WITH RECURSIVE`) to generate 5,000 and 10,000 deterministic sample rows, requiring `SET SESSION cte_max_recursion_depth`.

The source PDFs and the SQL scripts are organized separately by experiment. The experiment-specific READMEs embed the full code and document the expected outputs.

---

## How to Run an Experiment

```bash
# Example: run Experiment 7 from the command line
mysql -u <user> -p < "Experiment 7/Exp7.sql"
```

Or open the `.sql` file in MySQL Workbench or any online MySQL compiler (for example ByteXL) and run it.
