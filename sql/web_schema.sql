-- =========================================================
-- web_schema.sql
-- Schema for Auto-Parts Web Application (NO demo data)
-- Creates/extends all tables + view used by app.py
-- Safe to re-run (idempotent-ish).
-- =========================================================

SET SERVEROUTPUT ON

-- Optional sanity check
SHOW USER
SELECT sys_context('USERENV','DB_NAME') AS db_name,
       sys_context('USERENV','CON_NAME') AS pdb
FROM dual;

------------------------------------------------------------
-- 1) Base tables (from original schema.sql, DDL only)
------------------------------------------------------------

---------------------------
-- TABLE: MAKE
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE make (
      make_id   NUMBER CONSTRAINT pk_make PRIMARY KEY,
      make_name VARCHAR2(100) CONSTRAINT nn_make_name NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: TRIM
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE trim (
      trim_id   NUMBER CONSTRAINT pk_trim PRIMARY KEY,
      trim_name VARCHAR2(50)  CONSTRAINT nn_trim_name NOT NULL,
      make_id   NUMBER        CONSTRAINT nn_trim_make  NOT NULL,
      CONSTRAINT fk_trim_make FOREIGN KEY (make_id) REFERENCES make(make_id)
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: ENGINE_SPEC
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE engine_spec (
      engine_id   NUMBER CONSTRAINT pk_engine_spec PRIMARY KEY,
      engine_code VARCHAR2(50) CONSTRAINT nn_engine_code NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: DRIVE_TRAIN
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE drive_train (
      drive_id   NUMBER CONSTRAINT pk_drive_train PRIMARY KEY,
      drive_code VARCHAR2(20) CONSTRAINT nn_drive_code NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: POSITION
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE position (
      position_id   NUMBER CONSTRAINT pk_position PRIMARY KEY,
      position_code VARCHAR2(20) CONSTRAINT nn_position_code NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: BRAND
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE brand (
      brand_id   NUMBER CONSTRAINT pk_brand PRIMARY KEY,
      brand_name VARCHAR2(100) CONSTRAINT nn_brand_name NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: PART_TYPE
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE part_type (
      part_type_id   NUMBER CONSTRAINT pk_part_type PRIMARY KEY,
      parttype_name  VARCHAR2(100) CONSTRAINT nn_parttype_name NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: PARTTYPE_BRAND (bridge)
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE parttype_brand (
      part_type_id NUMBER CONSTRAINT nn_ptb_parttype NOT NULL,
      brand_id     NUMBER CONSTRAINT nn_ptb_brand    NOT NULL,
      CONSTRAINT pk_parttype_brand PRIMARY KEY (part_type_id, brand_id),
      CONSTRAINT fk_ptb_parttype FOREIGN KEY (part_type_id) REFERENCES part_type(part_type_id),
      CONSTRAINT fk_ptb_brand    FOREIGN KEY (brand_id)     REFERENCES brand(brand_id)
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

---------------------------
-- TABLE: LISTING
---------------------------
DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE listing (
      listing_id    NUMBER CONSTRAINT pk_listing PRIMARY KEY,
      listing_title VARCHAR2(200) CONSTRAINT nn_listing_title NOT NULL,
      price         NUMBER(10,2),
      brand_id      NUMBER CONSTRAINT nn_listing_brand NOT NULL,
      part_type_id  NUMBER CONSTRAINT nn_listing_pt    NOT NULL,
      CONSTRAINT fk_listing_brand     FOREIGN KEY (brand_id)     REFERENCES brand(brand_id),
      CONSTRAINT fk_listing_part_type FOREIGN KEY (part_type_id) REFERENCES part_type(part_type_id)
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

------------------------------------------------------------
-- 2) Unique constraints (safe, ignore if already present)
------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE make ADD CONSTRAINT uk_make_name UNIQUE(make_name)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-2261, -2264) THEN RAISE; END IF; END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE brand ADD CONSTRAINT uk_brand_name UNIQUE(brand_name)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-2261, -2264) THEN RAISE; END IF; END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE part_type ADD CONSTRAINT uk_parttype_name UNIQUE(parttype_name)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-2261, -2264) THEN RAISE; END IF; END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE drive_train ADD CONSTRAINT uk_drive_code UNIQUE(drive_code)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-2261, -2264) THEN RAISE; END IF; END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE position ADD CONSTRAINT uk_position_code UNIQUE(position_code)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-2261, -2264) THEN RAISE; END IF; END;
/

------------------------------------------------------------
-- 3) MODEL table (new)
------------------------------------------------------------

DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
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
EXCEPTION WHEN e_exists THEN NULL; END;
/

BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE OR REPLACE TRIGGER trg_trim_set_make
    BEFORE INSERT OR UPDATE ON trim
    FOR EACH ROW
  BEGIN
    IF :NEW.model_id IS NOT NULL THEN
      SELECT make_id
      INTO   :NEW.make_id
      FROM   model
      WHERE  model_id = :NEW.model_id;
    END IF;
  END;
  ]';
EXCEPTION
  WHEN OTHERS THEN
    -- Ignore "compilation error" at create time; SHOW ERRORS will reveal if it’s broken
    NULL;
END;
/
------------------------------------------------------------
-- 4) Extend TRIM: add YEAR and MODEL_ID
------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE trim ADD (year NUMBER(4))';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE trim ADD (model_id NUMBER)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE trim ADD CONSTRAINT fk_trim_model
    FOREIGN KEY (model_id) REFERENCES model(model_id)
  ';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-2275) THEN RAISE; END IF;
END;
/

------------------------------------------------------------
-- 5) Extend LISTING: add TRIM_ID, DRIVE_ID, POSITION_ID, MPN
------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (trim_id NUMBER)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (drive_id NUMBER)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (position_id NUMBER)';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE listing ADD (mpn VARCHAR2(100))';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_trim
    FOREIGN KEY (trim_id) REFERENCES trim(trim_id)
  ';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-2275) THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_drive
    FOREIGN KEY (drive_id) REFERENCES drive_train(drive_id)
  ';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-2275) THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE '
    ALTER TABLE listing ADD CONSTRAINT fk_listing_position
    FOREIGN KEY (position_id) REFERENCES position(position_id)
  ';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-2275) THEN RAISE; END IF;
END;
/

------------------------------------------------------------
-- 6) BRAND_ALIAS table (for data-quality / alias collisions)
------------------------------------------------------------

DECLARE
  e_exists EXCEPTION; PRAGMA EXCEPTION_INIT(e_exists, -955);
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE brand_alias (
      alias_text      VARCHAR2(100) NOT NULL,
      canonical_value VARCHAR2(100) NOT NULL
    )
  ]';
EXCEPTION WHEN e_exists THEN NULL; END;
/

-- No inserts here – you will populate this from your own data.

------------------------------------------------------------
-- 7) View: View_NormalizedFitment
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
  lf.trim_id,
  t.trim_name,
  t.year,
  t.make_id,
  mk.make_name,
  t.model_id,
  md.model_name,
  lf.position_id,
  p.position_code,
  lf.drive_id,
  d.drive_code
FROM listing l
JOIN brand b
  ON l.brand_id = b.brand_id
JOIN part_type pt
  ON l.part_type_id = pt.part_type_id
JOIN listing_fitment lf
  ON l.listing_id = lf.listing_id
JOIN trim t
  ON lf.trim_id = t.trim_id
JOIN make mk
  ON t.make_id = mk.make_id
JOIN model md
  ON t.model_id = md.model_id
JOIN position p
  ON lf.position_id = p.position_id
JOIN drive_train d
  ON lf.drive_id = d.drive_id;

COMMIT;

PROMPT === web_schema.sql completed (no demo data inserted) ===