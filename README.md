# RDBMS-Lab

Semester 3 DBMS lab experiments 1–6.

This repository contains the DBMS laboratory experiments in order. Experiments 1 and 2 preserve the supplied PDF files. Experiments 3–6 each have a separate MySQL source file and a detailed experiment README with the aim, explanation, run guidance, source code, and expected output.

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

### Topics at a Glance

| Experiment | Key concepts |
|---|---|
| 1 | Entities, attributes, relationships, cardinality, ER modelling |
| 2 | Relational schema, primary keys, foreign keys, `NOT NULL`, `UNIQUE`, `CHECK` constraints |
| 3 | Employee, department and project tables; data retrieval queries |
| 4 | `INNER JOIN`, `LEFT JOIN`, self-join, 3-way join, correlated subquery, `EXISTS`, simulated `INTERSECT` / `EXCEPT`, `EXPLAIN` |
| 5 | Views, view updatability, recursive CTE (`WITH RECURSIVE`) |
| 6 | Stored procedure with transaction and error handling, `BEFORE` / `AFTER` triggers, salary audit table |

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
└── Experiment 6/
    ├── README.md
    ├── DBMS_Experiment_6_Stored_Procedure_Triggers_Krishna.pdf
    └── Exp6.sql
```

---

## Database Setup

Experiments 2–6 use **MySQL 8.0+**. Each script creates or resets its own sample tables, so every script can be re-run safely.

| Experiment | Database used |
|---|---|
| 4 | `DBMS_LAB` |
| 5 | `DBMS_VIEW_LAB` |
| 6 | `DBMS_LAB` |

Run **one experiment script at a time** in a MySQL client. Experiments 4 and 6 reset tables in `DBMS_LAB`, so running them one after the other replaces the previous sample data.

Experiment 6 uses a stored procedure and triggers and therefore requires support for the `DELIMITER` client command. Each experiment README describes its expected result set and any statements that need to be run separately (for example, statements that are meant to raise an error).

The source PDFs and the SQL scripts are organized separately by experiment. The experiment-specific READMEs embed the full code and document the expected outputs.

---

## How to Run an Experiment

```bash
# Example: run Experiment 5 from the command line
mysql -u <user> -p < "Experiment 5/Exp5.sql"
```

Or open the `.sql` file in MySQL Workbench or any online MySQL compiler (for example ByteXL) and run it.

---

## Tools Used

- MySQL 8.0+
- MySQL Workbench / MySQL CLI
- ByteXL online SQL compiler
