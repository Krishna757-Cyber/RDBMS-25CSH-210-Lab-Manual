# DBMS-LAB-EXPERIMENTS

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
| 1 | Indian e-commerce ER diagram | [Experiment 1 README](Experiment-1/README.md) · [Original PDF](Experiment-1/Experiment_1.pdf) |
| 2 | Relational schema and MySQL constraints | [Experiment 2 README](Experiment-2/README.md) · [Original PDF](Experiment-2/Experiment_2.pdf) |
| 3 | Employee, department, and project queries | [Experiment 3 README](Experiment-3/README.md) · [SQL source](Experiment-3/experiment_3.sql) |
| 4 | Joins, subqueries, and query plans | [Experiment 4 README](Experiment-4/README.md) · [SQL source](Experiment-4/experiment_4.sql) |
| 5 | Views and recursive reporting chain | [Experiment 5 README](Experiment-5/README.md) · [SQL source](Experiment-5/experiment_5.sql) |
| 6 | Stored procedure, validation, and audit triggers | [Experiment 6 README](Experiment-6/README.md) · [SQL source](Experiment-6/experiment_6.sql) |

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
DBMS-LAB-EXPERIMENTS/
├── README.md
├── Experiment-1/
│   ├── README.md
│   └── Experiment_1.pdf
├── Experiment-2/
│   ├── README.md
│   └── Experiment_2.pdf
├── Experiment-3/
│   ├── README.md
│   └── experiment_3.sql
├── Experiment-4/
│   ├── README.md
│   └── experiment_4.sql
├── Experiment-5/
│   ├── README.md
│   └── experiment_5.sql
└── Experiment-6/
    ├── README.md
    └── experiment_6.sql
```

---

## Database Setup

Experiments 3–6 use **MySQL 8.0+**. Each script creates or resets its own sample tables, so every script can be re-run safely.

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
mysql -u <user> -p < Experiment-5/experiment_5.sql
```

Or open the `.sql` file in MySQL Workbench or any online MySQL compiler (for example ByteXL) and run it.

---

## Tools Used

- MySQL 8.0+
- MySQL Workbench / MySQL CLI
- ByteXL online SQL compiler
