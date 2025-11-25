# Auto Parts Fitment Explorer

A single-page Gradio web application for searching auto parts fitment, analyzing brand coverage, inspecting data quality, and exploring database schema.

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set environment variables:**
   ```bash
   export ORA_USER=your_username
   export ORA_PASS=your_password
   export ORA_DB=localhost:1521/XEPDB1
   ```
   
   Or on Windows:
   ```powershell
   $env:ORA_USER="your_username"
   $env:ORA_PASS="your_password"
   $env:ORA_DB="localhost:1521/XEPDB1"
   ```

3. **Run the application:**
   ```bash
   python app.py
   ```

   The application will be available at `http://localhost:7860`

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





