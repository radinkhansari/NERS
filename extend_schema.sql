-- =========================================================
-- extend_schema.sql
-- Extend existing CPS510 Auto-Parts schema for web app
-- Run this AFTER your original schema.sql (and seed.sql).
-- =========================================================

SET SERVEROUTPUT ON

-- Optional: sanity check
SHOW USER
SELECT sys_context('USERENV','DB_NAME') AS db_name,
       sys_context('USERENV','CON_NAME') AS pdb
FROM dual;

------------------------------------------------------------
-- 1) MODEL table
------------------------------------------------------------

DECLARE
  e_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE model (
      model_id   NUMBER CONSTRAINT pk_model PRIMARY KEY,
      model_name VARCHAR2(100) CONSTRAINT nn_model_name NOT NULL,
      make_id    NUMBER CONSTRAINT nn_model_make NOT NULL,
      CONSTRAINT fk_model_make
        FOREIGN KEY (make_id) REFERENCES make(make_id)
    )
  ]';
EXCEPTION
  WHEN e_exists THEN
    NULL; -- table already exists, do nothing
END;
/

------------------------------------------------------------
-- 2) Extend TRIM: add YEAR and MODEL_ID
------------------------------------------------------------

-- Add YEAR column
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE trim ADD (year NUMBER(4))';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN -- ORA-01430: column being added already exists
      RAISE;
    END IF;
END;
/

-- Add MODEL_ID column
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE trim ADD (model_id NUMBER)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN
      RAISE;
    END IF;
END;
/

-- Add foreign key TRIM.MODEL_ID -> MODEL.MODEL_ID
BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE trim ADD CONSTRAINT fk_trim_model
    FOREIGN KEY (model_id) REFERENCES model(model_id)
  ';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-02275 "such a referential constraint already exists in the table"
    IF SQLCODE NOT IN (-2275) THEN
      RAISE;
    END IF;
END;
/

------------------------------------------------------------
-- 3) Extend LISTING: add TRIM_ID, DRIVE_ID, POSITION_ID, MPN
------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (trim_id NUMBER)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (drive_id NUMBER)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (position_id NUMBER)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (mpn VARCHAR2(100))';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN
      RAISE;
    END IF;
END;
/

-- Add foreign keys from LISTING to TRIM / DRIVE_TRAIN / POSITION

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_trim
    FOREIGN KEY (trim_id) REFERENCES trim(trim_id)
  ';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE NOT IN (-2275) THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_drive
    FOREIGN KEY (drive_id) REFERENCES drive_train(drive_id)
  ';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE NOT IN (-2275) THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_position
    FOREIGN KEY (position_id) REFERENCES position(position_id)
  ';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE NOT IN (-2275) THEN
      RAISE;
    END IF;
END;
/

------------------------------------------------------------
-- 4) BRAND_ALIAS table (for alias collision checks)
------------------------------------------------------------

DECLARE
  e_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE brand_alias (
      alias_text      VARCHAR2(100) NOT NULL,
      canonical_value VARCHAR2(100) NOT NULL
    )
  ]';
EXCEPTION
  WHEN e_exists THEN
    NULL;
END;
/

-- Sample alias data including a collision
INSERT INTO brand_alias (alias_text, canonical_value)
SELECT 'TOYOTA', 'Toyota'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM brand_alias
  WHERE alias_text = 'TOYOTA' AND canonical_value = 'Toyota'
);

INSERT INTO brand_alias (alias_text, canonical_value)
SELECT 'TOYOTA', 'TOYOTA MOTOR'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM brand_alias
  WHERE alias_text = 'TOYOTA' AND canonical_value = 'TOYOTA MOTOR'
);

INSERT INTO brand_alias (alias_text, canonical_value)
SELECT 'HONDA', 'Honda'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM brand_alias
  WHERE alias_text = 'HONDA' AND canonical_value = 'Honda'
);

------------------------------------------------------------
-- 5) Seed / update MODEL + TRIM + LISTING relationships
--    (minimal data just so filters actually have something)
------------------------------------------------------------

-- Example make: your schema already inserts make_id = 1234 'Sample Make'
-- We'll reuse that and create one model under it.

MERGE INTO model m
USING (
  SELECT 1 AS model_id,
         'Sample Model' AS model_name,
         1234 AS make_id
  FROM dual
) src
ON (m.model_id = src.model_id)
WHEN NOT MATCHED THEN
  INSERT (model_id, model_name, make_id)
  VALUES (src.model_id, src.model_name, src.make_id);

-- Attach trims to that model + assign years
UPDATE trim
SET model_id = 1,
    year     = 2020
WHERE trim_id = 1
  AND (model_id IS NULL OR year IS NULL);

UPDATE trim
SET model_id = 1,
    year     = 2021
WHERE trim_id = 2
  AND (model_id IS NULL OR year IS NULL);

-- Attach some listings to trims / drive / position so filters work

-- Make sure drive_train and position rows exist (your schema.sql seeds them already,
-- but we guard it anyway)

INSERT INTO drive_train (drive_id, drive_code)
SELECT 1, 'AWD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 1);

INSERT INTO drive_train (drive_id, drive_code)
SELECT 2, 'FWD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 2);

INSERT INTO position (position_id, position_code)
SELECT 1, 'FRONT' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM position WHERE position_id = 1);

INSERT INTO position (position_id, position_code)
SELECT 2, 'REAR' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM position WHERE position_id = 2);

-- Update your existing listings to hook them into fitment data
UPDATE listing
SET trim_id    = 1,
    drive_id   = 1,
    position_id = 1,
    mpn        = 'MPN-ENG-001'
WHERE listing_id = 1;

UPDATE listing
SET trim_id    = 2,
    drive_id   = 2,
    position_id = 2,
    mpn        = NULL -- so missing-MPN query finds something
WHERE listing_id = 2;

-- Leave others partially filled; they’ll still show up without filters.

------------------------------------------------------------
-- 6) View: View_NormalizedFitment
-- This is what app.py queries in search_fitment() and compute_coverage()
------------------------------------------------------------

CREATE OR REPLACE VIEW View_NormalizedFitment AS
SELECT
  l.listing_id,
  l.listing_title,
  l.price,
  l.brand_id,
  b.brand_name,
  l.part_type_id,
  pt.parttype_name,
  l.trim_id,
  t.trim_name,
  t.year,
  t.make_id,
  mk.make_name,
  t.model_id,
  md.model_name,
  l.position_id,
  p.position_code,
  l.drive_id,
  d.drive_code
FROM listing l
JOIN brand b
  ON l.brand_id = b.brand_id
JOIN part_type pt
  ON l.part_type_id = pt.part_type_id
LEFT JOIN trim t
  ON l.trim_id = t.trim_id
LEFT JOIN make mk
  ON t.make_id = mk.make_id
LEFT JOIN model md
  ON t.model_id = md.model_id
LEFT JOIN position p
  ON l.position_id = p.position_id
LEFT JOIN drive_train d
  ON l.drive_id = d.drive_id;

COMMIT;

PROMPT === extend_schema.sql completed ===