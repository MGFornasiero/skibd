# skibd
Karate Shotokan Database

## Overview
This database is designed to support the Karate Shotokan API, providing structured data for techniques, stances, grades, kihon, and kata. The database is implemented in PostgreSQL and includes schemas, tables, functions, and triggers to manage and query data efficiently.

## Structure
- **Schemas**:
  - `ski`: Main schema containing domain tables and data.
  - `staging`: Temporary schema for data ingestion.
  - `upsert`: Schema for tracking successful updates and inserts.
  - `reject`: Schema for tracking rejected data.
  - `bkp`: Schema for data backups.

- **Custom Types**:
  - Includes enums for karate-specific concepts such as `grade_type`, `waza_type`, `tempo`, etc.

- **Domain Tables**:
  - `targets`, `strikingparts`, `technics`, `stands`, `grades`: Core entities for karate techniques and stances.

- **Compendium Tables**:
  - `kihon_inventory`, `kihon_sequences`, `kata_inventory`, `kata_sequence`: Detailed sequences for kihon and kata.

- **Indexes**:
  - Full-text search (FTS) indexes for efficient querying.
  - Join optimization indexes for faster data retrieval.

- **Functions**:
  - Functions for retrieving specific data, such as `get_gradeid`, `get_kihon_steps`, `get_katasequence`, etc.

- **Triggers**:
  - Triggers on staging tables to automate data validation, insertion, and updates.

- **Backup Mechanism**:
  - A procedure (`ski.bkp`) for periodic data backups.

## Integration with API
The database is used as the data source for the FastAPI application (`main.py`). The API endpoints query the database to provide data for karate techniques, stances, grades, kihon, and kata.

## Usage
1. **Setup**:
   - Run the `DDL.sql` script to create the database structure.
   - Use the staging tables for data ingestion.

2. **Connection**:
   - Example connection: `./cloud-sql-proxy.exe --address 127.0.0.1 --port 5432 eng-hangar-343507:europe-west12:pg-mgion`

3. **API**:
   - The API endpoints in `main.py` interact with the database to retrieve and manipulate data.

4. **Backup**:
   - Use the `ski.bkp` procedure to create backups of the `ski` schema.

## Notes
- Ensure the `SKIURI` environment variable is set for database connection.
- The database supports full-text search for efficient querying of techniques, stances, and other entities.
