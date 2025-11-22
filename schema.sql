-- =========================================
-- schema.sql  (idempotent)
-- =========================================

-- (Optional) sanity: who/where am I?
SHOW USER
SELECT sys_context('USERENV','DB_NAME') AS db_name,
       sys_context('USERENV','CON_NAME') AS pdb
FROM dual;

-- Helper: ORA-955 (object exists) ignore pattern used below.

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
-- NOTE: No UNIQUE on engine_code (duplicates allowed for frequency tests)

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

-- ---------------------------------------------------------
-- Optional: add UNIQUE constraints with safe handler
-- (Ignore if equivalent key already exists: ORA-02261/02264)
-- ---------------------------------------------------------
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

-- =========================================================
-- SEED DATA (idempotent via INSERT...WHERE NOT EXISTS)
-- =========================================================

-- MAKE
INSERT INTO make (make_id, make_name)
SELECT 1234, 'Sample Make' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM make WHERE make_id = 1234);

-- BRAND
INSERT INTO brand (brand_id, brand_name)
SELECT 1, 'Toyota' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM brand WHERE brand_id = 1);
INSERT INTO brand (brand_id, brand_name)
SELECT 2, 'Honda' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM brand WHERE brand_id = 2);
INSERT INTO brand (brand_id, brand_name)
SELECT 3, 'Ford' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM brand WHERE brand_id = 3);
INSERT INTO brand (brand_id, brand_name)
SELECT 4, 'Chevrolet' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM brand WHERE brand_id = 4);

-- TRIM
INSERT INTO trim (trim_id, trim_name, make_id)
SELECT 1, 'Sport', 1234 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM trim WHERE trim_id = 1);
INSERT INTO trim (trim_id, trim_name, make_id)
SELECT 2, 'Luxury', 1234 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM trim WHERE trim_id = 2);

-- PART_TYPE
INSERT INTO part_type (part_type_id, parttype_name)
SELECT 1, 'Engine' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM part_type WHERE part_type_id = 1);
INSERT INTO part_type (part_type_id, parttype_name)
SELECT 2, 'Transmission' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM part_type WHERE part_type_id = 2);
INSERT INTO part_type (part_type_id, parttype_name)
SELECT 3, 'Brakes' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM part_type WHERE part_type_id = 3);
INSERT INTO part_type (part_type_id, parttype_name)
SELECT 4, 'Suspension' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM part_type WHERE part_type_id = 4);

-- PARTTYPE_BRAND
INSERT INTO parttype_brand (part_type_id, brand_id)
SELECT 1, 1 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM parttype_brand WHERE part_type_id = 1 AND brand_id = 1);
INSERT INTO parttype_brand (part_type_id, brand_id)
SELECT 2, 2 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM parttype_brand WHERE part_type_id = 2 AND brand_id = 2);
INSERT INTO parttype_brand (part_type_id, brand_id)
SELECT 3, 3 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM parttype_brand WHERE part_type_id = 3 AND brand_id = 3);
INSERT INTO parttype_brand (part_type_id, brand_id)
SELECT 4, 4 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM parttype_brand WHERE part_type_id = 4 AND brand_id = 4);

-- LISTING
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 1, 'Toyota Engine for sale', 500.00, 1, 1 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 1);
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 2, 'Honda Transmission for sale', 400.00, 2, 2 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 2);
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 3, 'Ford Brake for sale', 150.00, 3, 3 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 3);
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 4, 'Chevrolet Suspension for sale', 300.00, 4, 4 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 4);
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 5, 'Toyota Engine for sale', 600.00, 1, 1 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 5);
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id)
SELECT 6, 'Chevrolet Suspension for sale', 350.00, 4, 4 FROM dual
WHERE NOT EXISTS (SELECT 1 FROM listing WHERE listing_id = 6);

-- ENGINE_SPEC (duplicates allowed)
INSERT INTO engine_spec (engine_id, engine_code)
SELECT 1, 'V8' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM engine_spec WHERE engine_id = 1);
INSERT INTO engine_spec (engine_id, engine_code)
SELECT 2, 'V6' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM engine_spec WHERE engine_id = 2);
INSERT INTO engine_spec (engine_id, engine_code)
SELECT 3, 'V8' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM engine_spec WHERE engine_id = 3);
INSERT INTO engine_spec (engine_id, engine_code)
SELECT 4, 'I4' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM engine_spec WHERE engine_id = 4);
INSERT INTO engine_spec (engine_id, engine_code)
SELECT 5, 'V6' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM engine_spec WHERE engine_id = 5);

-- DRIVE_TRAIN
INSERT INTO drive_train (drive_id, drive_code)
SELECT 1, 'AWD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 1);
INSERT INTO drive_train (drive_id, drive_code)
SELECT 2, 'FWD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 2);
INSERT INTO drive_train (drive_id, drive_code)
SELECT 3, 'RWD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 3);
INSERT INTO drive_train (drive_id, drive_code)
SELECT 4, '4WD' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM drive_train WHERE drive_id = 4);

-- POSITION
INSERT INTO position (position_id, position_code)
SELECT 1, 'FRONT' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM position WHERE position_id = 1);
INSERT INTO position (position_id, position_code)
SELECT 2, 'REAR' FROM dual
WHERE NOT EXISTS (SELECT 1 FROM position WHERE position_id = 2);

COMMIT;