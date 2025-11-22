
# Auto Parts Fitment Explorer

A single-page Gradio web application for searching auto parts fitment, analyzing brand coverage, inspecting data quality, and exploring database schema.

## Prerequisites

- **Docker** (for running Oracle database)
- **Python 3.8+** with conda/pip
- **Oracle Client Libraries** (included via `oracledb` Python package)

## Complete Setup Guide

### Step 1: Install Docker (if not already installed)

**Linux/macOS:**
- Follow instructions at: https://docs.docker.com/get-docker/

**Windows:**
- Download Docker Desktop from: https://www.docker.com/products/docker-desktop
- Install and start Docker Desktop

Verify Docker is running:
```bash
docker --version
```

### Step 2: Download and Run Oracle Database Docker Image

The application uses Oracle Database Express Edition (XE) running in a Docker container.

**Pull the Oracle XE image:**
```bash
docker pull container-registry.oracle.com/database/express:latest
```

**Note:** You may need to accept Oracle's license agreement. If the pull fails, you can also use:
```bash
docker pull gvenzl/oracle-xe:latest
```

**Run the Oracle container:**
```bash
docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=oracle \
  -e ORACLE_CHARACTERSET=AL32UTF8 \
  container-registry.oracle.com/database/express:latest
```

Or using the alternative image:
```bash
docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PASSWORD=oracle \
  gvenzl/oracle-xe:latest
```

**Wait for Oracle to start** (this takes 1-2 minutes):
```bash
# Check container status
docker ps | grep oracle-xe

# View logs to see when it's ready
docker logs -f oracle-xe
```

Wait until you see: `DATABASE IS READY TO USE!`

**Verify the container is running:**
```bash
docker ps | grep oracle-xe
```

**Default credentials:**
- Username: `system`
- Password: `oracle` (or whatever you set in `ORACLE_PWD`/`ORACLE_PASSWORD`)
- Database: `XEPDB1`
- Connection: `localhost:1521/XEPDB1`

### Step 3: Set Up Database Schema

**Run the schema setup script:**
```bash
bash run.sh
```

This will:
1. Create all required tables
2. Create the `listing_fitment` bridge table
3. Fix the `View_NormalizedFitment` view

**Populate with demo data:**
```bash
docker exec -i oracle-xe sqlplus system/oracle@localhost:1521/XEPDB1 @sql/web_demo_seed.sql
```

Or if using the alternative image:
```bash
docker exec -i oracle-xe sqlplus system/oracle@XEPDB1 @sql/web_demo_seed.sql
```

### Step 4: Install Python Dependencies

**Create and activate conda environment (recommended):**
```bash
conda create -n cps510 python=3.11
conda activate cps510
```

**Install dependencies:**
```bash
pip install -r requirements.txt
```

### Step 5: Set Environment Variables

**Linux/macOS:**
```bash
export ORA_USER=system
export ORA_PASS=oracle
export ORA_DB=localhost:1521/XEPDB1
```

**Windows (PowerShell):**
```powershell
$env:ORA_USER="system"
$env:ORA_PASS="oracle"
$env:ORA_DB="localhost:1521/XEPDB1"
```

**Windows (Command Prompt):**
```cmd
set ORA_USER=system
set ORA_PASS=oracle
set ORA_DB=localhost:1521/XEPDB1
```

### Step 6: Run the Application

```bash
python app.py
```

The application will be available at `http://localhost:7860`

## Quick Start (If Oracle is Already Running)

If you already have Oracle running:

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set environment variables:**
   ```bash
   export ORA_USER=system
   export ORA_PASS=oracle
   export ORA_DB=localhost:1521/XEPDB1
   ```

3. **Run the application:**
   ```bash
   python app.py
   ```

## Features

- **Header & Quick Stats**: Displays total listings, brands, and trims
- **Fitment Search**: Search parts by make, model, year, trim, part type, position, drive, price range, and brands
- **Brand & Part Coverage**: Analytics showing brand and part type coverage statistics
- **Data Quality**: Inspect alias collisions, missing MPNs, and OEM descriptor mismatches
- **Schema Peek**: Preview any table in the database (first 50 rows)

## Database Schema Requirements

The application expects the following tables/views:
- `MAKE`, `MODEL`, `TRIM`, `POSITION`, `DRIVE_TRAIN`, `PART_TYPE`, `BRAND`, `LISTING`
- `View_NormalizedFitment` (or equivalent view with normalized fitment data)

Adjust table/view names in the code if your schema differs.

## Notes

- The application is read-only (no inserts/updates)
- All queries use parameterized SQL for security
- Connection pooling is used for efficient database access
- The alias collisions query may need adjustment based on your actual schema