# Step-by-Step Setup Guide for Auto Parts Fitment Explorer

This guide will help you set up the database schema and fix the view to work with the `listing_fitment` bridge table.

## Prerequisites

- Oracle database running (Docker container `oracle-xe` or local instance)
- Conda environment `cps510` activated
- All SQL files in the `sql/` directory

## Step-by-Step Instructions

### Step 1: Ensure Oracle Database is Running

**If using Docker:**
```bash
docker ps | grep oracle-xe
```

If the container is not running, start it:
```bash
docker start oracle-xe
```

**If using local Oracle:**
Make sure your Oracle database service is running.

---

### Step 2: Run the Schema Setup Script

The `run.sh` script will:
1. Create the base schema (tables, foreign keys)
2. Create the `listing_fitment` bridge table
3. Fix the `View_NormalizedFitment` to use the bridge table

**Run the script:**
```bash
bash run.sh
```

**Or if you prefer to set credentials beforehand:**
```bash
export ORA_USER=system
export ORA_PASS=oracle
export ORA_DB=localhost:1521/XEPDB1
bash run.sh
```

The script will prompt you for credentials if they're not set.

**Expected output:**
```
=== Auto-Parts Web Schema Setup ===
SQL directory: /path/to/cps510/sql

▶ Web schema (tables, FKs, view)
   File: sql/web_schema.sql
=========================================
[SQL output...]

▶ Create listing_fitment bridge table
   File: sql/add_listing_fitment.sql
=========================================
[SQL output...]

▶ Fix View_NormalizedFitment to use listing_fitment
   File: sql/fix_view.sql
=========================================
[SQL output...]

=========================================
Schema prep complete (no demo data).
...
```

---

### Step 3: Populate with Demo Data

After the schema is set up, populate it with demo data:

**Option A: Using sqlplus directly**
```bash
sqlplus system/oracle@localhost:1521/XEPDB1 @sql/web_demo_seed.sql
```

**Option B: Using Docker (if using Docker container)**
```bash
docker exec -i oracle-xe sqlplus system/oracle@localhost:1521/XEPDB1 @sql/web_demo_seed.sql
```

**Option C: Using the credentials from run.sh**
```bash
# Use the same credentials you used in run.sh
sqlplus ${ORA_USER}/${ORA_PASS}@${ORA_DB} @sql/web_demo_seed.sql
```

**Expected output:**
```
=== Clearing existing Auto-Parts demo data ===
=== Inserting lookup data (makes, models, trims, etc.) ===
=== Inserting listings ===
=== Inserting listing fitment mappings ===
=== web_demo_seed.sql complete: lookup tables + ~30 listings + rich fitment ===
```

---

### Step 4: Set Environment Variables

Set the Oracle connection environment variables:

```bash
export ORA_USER=system
export ORA_PASS=oracle
export ORA_DB=localhost:1521/XEPDB1
```

**For Windows (PowerShell):**
```powershell
$env:ORA_USER="system"
$env:ORA_PASS="oracle"
$env:ORA_DB="localhost:1521/XEPDB1"
```

---

### Step 5: Activate Conda Environment and Run the App

```bash
conda activate cps510
python app.py
```

**Expected output:**
```
INFO:__main__:Oracle connection pool created successfully
INFO:__main__:Application initialized successfully
INFO:__main__:Loaded 7 makes
* Running on local URL:  http://0.0.0.0:7860
```

---

### Step 6: Test the Application

1. Open your browser and go to: `http://localhost:7860`

2. **Check Quick Stats:**
   - Total Listings should show a number > 0
   - Total Brands should show 10
   - Total Trims should show 24

3. **Test Fitment Search:**
   - Select a Make (e.g., "Ford")
   - Select a Model (e.g., "F-150" or "Focus")
   - Click "Search Fitment"
   - You should see results!

4. **Test Other Tabs:**
   - Brand & Part Coverage
   - Data Quality
   - Schema Peek

---

## Troubleshooting

### Issue: "View_NormalizedFitment" not found or returns no results

**Solution:** Make sure you ran `fix_view.sql`. You can verify by:
```sql
SELECT COUNT(*) FROM View_NormalizedFitment;
```

If it returns 0 and you have listings, the view might not be fixed. Re-run:
```bash
sqlplus system/oracle@localhost:1521/XEPDB1 @sql/fix_view.sql
```

### Issue: "Total Listings: 0" in the app

**Solution:** You need to populate the database with demo data:
```bash
sqlplus system/oracle@localhost:1521/XEPDB1 @sql/web_demo_seed.sql
```

### Issue: "No results found" when searching

**Check:**
1. Verify listings exist: `SELECT COUNT(*) FROM listing;`
2. Verify listing_fitment has data: `SELECT COUNT(*) FROM listing_fitment;`
3. Verify the view works: `SELECT COUNT(*) FROM View_NormalizedFitment;`

If all three return > 0, the search should work.

### Issue: Connection errors

**Check:**
- Oracle database is running
- Credentials are correct
- Connection string format: `host:port/service_name` (e.g., `localhost:1521/XEPDB1`)

---

## Quick Reference: File Execution Order

1. `sql/web_schema.sql` - Base schema (tables, constraints)
2. `sql/add_listing_fitment.sql` - Bridge table creation
3. `sql/fix_view.sql` - Fix view to use bridge table
4. `sql/web_demo_seed.sql` - Populate with demo data

All steps 1-3 are handled by `run.sh`. Step 4 must be run separately.

---

## What the Fix Does

The `fix_view.sql` script updates `View_NormalizedFitment` to:
- Join through `listing_fitment` bridge table instead of `listing.trim_id`
- Properly link listings to makes/models through the many-to-many relationship
- Support the schema structure used in `web_demo_seed.sql`

This allows one listing to fit multiple vehicle trims, which is the correct data model for auto parts.


