-- web_demo_seed.sql
-- Bigger, fully linked demo data for the Auto-Parts Fitment Explorer.
-- Assumes web_schema.sql (and add_listing_fitment.sql) have already been run.

SET SERVEROUTPUT ON
PROMPT === Clearing existing Auto-Parts demo data ===

-- Clear child tables first (ignore if some tables don't exist)
BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM listing_fitment';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM listing';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM parttype_brand';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM trim';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM model';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM make';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM brand_alias';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM brand';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM part_type';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM drive_train';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM position';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM engine_spec';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

COMMIT;

PROMPT === Inserting lookup data (makes, models, trims, etc.) ===

-------------------------------------------------------
-- MAKE
-------------------------------------------------------
INSERT INTO make (make_id, make_name) VALUES (1, 'Toyota');
INSERT INTO make (make_id, make_name) VALUES (2, 'Honda');
INSERT INTO make (make_id, make_name) VALUES (3, 'Ford');
INSERT INTO make (make_id, make_name) VALUES (4, 'BMW');
INSERT INTO make (make_id, make_name) VALUES (5, 'Chevrolet');
INSERT INTO make (make_id, make_name) VALUES (6, 'Nissan');
INSERT INTO make (make_id, make_name) VALUES (7, 'Hyundai');

-------------------------------------------------------
-- MODEL
-------------------------------------------------------
INSERT INTO model (model_id, model_name, make_id) VALUES (1,  'Corolla',    1);
INSERT INTO model (model_id, model_name, make_id) VALUES (2,  'Camry',      1);
INSERT INTO model (model_id, model_name, make_id) VALUES (3,  'Civic',      2);
INSERT INTO model (model_id, model_name, make_id) VALUES (4,  'Accord',     2);
INSERT INTO model (model_id, model_name, make_id) VALUES (5,  'F-150',      3);
INSERT INTO model (model_id, model_name, make_id) VALUES (6,  'Focus',      3);
INSERT INTO model (model_id, model_name, make_id) VALUES (7,  '3 Series',   4);
INSERT INTO model (model_id, model_name, make_id) VALUES (8,  'X5',         4);
INSERT INTO model (model_id, model_name, make_id) VALUES (9,  'Silverado',  5);
INSERT INTO model (model_id, model_name, make_id) VALUES (10, 'Cruze',      5);
INSERT INTO model (model_id, model_name, make_id) VALUES (11, 'Altima',     6);
INSERT INTO model (model_id, model_name, make_id) VALUES (12, 'Elantra',    7);

-------------------------------------------------------
-- TRIM (year + trim_name, all non-null)
-------------------------------------------------------
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (1,  'L',          1, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (2,  'SE',         1, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (3,  'SE',         1, 2020);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (4,  'LE',         2, 2019);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (5,  'XSE',        2, 2021);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (6,  'LX',         3, 2017);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (7,  'Sport',      3, 2019);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (8,  'EX',         4, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (9,  'Sport',      4, 2020);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (10, 'XL',         5, 2016);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (11, 'Lariat',     5, 2019);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (12, 'SE',         6, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (13, 'Titanium',   6, 2020);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (14, '330i',       7, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (15, '330i',       7, 2021);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (16, 'xDrive40i',  8, 2020);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (17, 'LT',         9, 2017);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (18, 'LTZ',        9, 2020);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (19, 'LT',         10, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (20, 'Premier',    10, 2021);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (21, 'S',          11, 2018);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (22, 'SV',         11, 2021);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (23, 'SE',         12, 2019);
INSERT INTO trim (trim_id, trim_name, model_id, year) VALUES (24, 'Limited',    12, 2021);

-------------------------------------------------------
-- ENGINE_SPEC (populated, even if not heavily used)
-------------------------------------------------------
INSERT INTO engine_spec (engine_id, engine_code) VALUES (1, 'I4');
INSERT INTO engine_spec (engine_id, engine_code) VALUES (2, 'I4 Turbo');
INSERT INTO engine_spec (engine_id, engine_code) VALUES (3, 'V6');
INSERT INTO engine_spec (engine_id, engine_code) VALUES (4, 'V8');
INSERT INTO engine_spec (engine_id, engine_code) VALUES (5, 'Hybrid');

-------------------------------------------------------
-- DRIVE_TRAIN
-------------------------------------------------------
INSERT INTO drive_train (drive_id, drive_code) VALUES (1, 'FWD');
INSERT INTO drive_train (drive_id, drive_code) VALUES (2, 'RWD');
INSERT INTO drive_train (drive_id, drive_code) VALUES (3, 'AWD');
INSERT INTO drive_train (drive_id, drive_code) VALUES (4, '4WD');

-------------------------------------------------------
-- POSITION
-------------------------------------------------------
INSERT INTO position (position_id, position_code) VALUES (1, 'FRONT');
INSERT INTO position (position_id, position_code) VALUES (2, 'REAR');
INSERT INTO position (position_id, position_code) VALUES (3, 'FRONT_LEFT');
INSERT INTO position (position_id, position_code) VALUES (4, 'FRONT_RIGHT');
INSERT INTO position (position_id, position_code) VALUES (5, 'REAR_LEFT');
INSERT INTO position (position_id, position_code) VALUES (6, 'REAR_RIGHT');

-------------------------------------------------------
-- BRAND
-------------------------------------------------------
INSERT INTO brand (brand_id, brand_name) VALUES (1,  'Toyota OEM');
INSERT INTO brand (brand_id, brand_name) VALUES (2,  'Honda OEM');
INSERT INTO brand (brand_id, brand_name) VALUES (3,  'Motorcraft');
INSERT INTO brand (brand_id, brand_name) VALUES (4,  'ACDelco');
INSERT INTO brand (brand_id, brand_name) VALUES (5,  'Brembo');
INSERT INTO brand (brand_id, brand_name) VALUES (6,  'Bosch');
INSERT INTO brand (brand_id, brand_name) VALUES (7,  'Monroe');
INSERT INTO brand (brand_id, brand_name) VALUES (8,  'KYB');
INSERT INTO brand (brand_id, brand_name) VALUES (9,  'Mann');
INSERT INTO brand (brand_id, brand_name) VALUES (10, 'Denso');

-------------------------------------------------------
-- PART_TYPE
-------------------------------------------------------
INSERT INTO part_type (part_type_id, parttype_name) VALUES (1, 'Brake Pad');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (2, 'Brake Rotor');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (3, 'Shock Absorber');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (4, 'Control Arm');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (5, 'Oil Filter');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (6, 'Air Filter');
INSERT INTO part_type (part_type_id, parttype_name) VALUES (7, 'Wiper Blade');

-------------------------------------------------------
-- PARTTYPE_BRAND (who sells what)
-------------------------------------------------------
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (1, 1);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (1, 2);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (1, 3);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (1, 4);

INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (2, 2);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (2, 3);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (2, 5);

INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (3, 4);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (3, 6);

INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (4, 7);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (4, 8);

INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (5, 9);
INSERT INTO parttype_brand (part_type_id, brand_id) VALUES (5, 10);

COMMIT;

-------------------------------------------------------
-- BRAND_ALIAS (for alias collision & cleaning demo)
-- matches brand_alias(alias_text, canonical_value)
-------------------------------------------------------
-- Normal aliases
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('BREMBO', 'Brembo');
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('Brembo Brakes', 'Brembo');
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('BMB', 'Brembo');

INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('HONDA', 'Honda OEM');
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('Honda Genuine', 'Honda OEM');

INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('TOYOTA OEM', 'Toyota OEM');

-- Collisions: same alias_text → multiple canonical_value
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('TOYOTA', 'Toyota OEM');
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('TOYOTA', 'TOYOTA Genuine');

INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('VAG', 'Volkswagen Group');
INSERT INTO brand_alias (alias_text, canonical_value) VALUES ('VAG', 'Audi / VW');

COMMIT;

-------------------------------------------------------
-- LISTING (about 30 rows, some with MPN, some without)
-------------------------------------------------------
PROMPT === Inserting listings ===

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (1,  'Toyota Corolla Front Brake Pad Kit 2018-2020', 90,  5, 1, 'BP-TCOR-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (2,  'Toyota Camry Performance Brake Pads 2019-2021', 110, 5, 1, 'BP-TCAM-19');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (3,  'Honda Civic Front Brake Pads 2017-2019', 85, 2, 1, 'BP-HCIV-17');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (4,  'Honda Accord Sport Brake Pads 2018-2020', 105, 2, 1, 'BP-HACC-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (5,  'Ford F-150 Heavy Duty Brake Pads 2016-2019', 120, 3, 1, 'BP-FF15-16');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (6,  'BMW 3 Series 330i Front Brake Pads 2018-2021', 180, 5, 1, 'BP-B3SR-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (7,  'Chevrolet Silverado Front Brake Pads 2017-2020', 115, 4, 1, 'BP-CSIL-17');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (8,  'Nissan Altima Front Brake Pads 2018-2021', 95,  6, 1, 'BP-NALT-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (9,  'Hyundai Elantra Front Brake Pads 2019-2021', 90,  6, 1, 'BP-HELA-19');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (10, 'Toyota Corolla Front Rotors Pair 2018-2020', 150, 5, 2, 'BR-TCOR-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (11, 'Honda Civic Front Rotors 2017-2019', 140, 5, 2, 'BR-HCIV-17');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (12, 'Ford F-150 Front Rotors 2016-2019', 190, 3, 2, 'BR-FF15-16');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (13, 'BMW 3 Series Front Rotors 2018-2021', 260, 5, 2, 'BR-B3SR-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (14, 'Chevrolet Silverado Front Rotors 2017-2020', 185, 4, 2, 'BR-CSIL-17');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (15, 'Nissan Altima Front Rotors 2018-2021', 155, 4, 2, 'BR-NALT-18');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (16, 'Hyundai Elantra Front Rotors 2019-2021', 150, 4, 2, 'BR-HELA-19');

-- Shocks (no MPN for some to demo "missing MPN")
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (17, 'Toyota Camry Rear Shock Absorbers 2019-2021', 220, 7, 3, NULL);

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (18, 'Honda Accord Rear Shock Absorbers 2018-2020', 210, 8, 3, NULL);

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (19, 'Ford F-150 Rear Shock Absorbers 2016-2019', 250, 7, 3, NULL);

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (20, 'BMW X5 Rear Shock Absorbers 2020', 360, 8, 3, NULL);

-- Control arms
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (21, 'Honda Civic Front Lower Control Arm 2017-2019', 180, 3, 4, 'CA-HCIV-17');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (22, 'Toyota Corolla Front Lower Control Arm 2018-2020', 175, 4, 4, 'CA-TCOR-18');

-- Filters
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (23, 'Toyota Corolla Oil Filter Pack (4 pcs)', 45, 9, 5, 'OF-TCOR');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (24, 'Honda Civic Oil Filter Pack (4 pcs)', 42, 9, 5, 'OF-HCIV');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (25, 'BMW 3 Series Oil Filter Pack (4 pcs)', 70, 9, 5, 'OF-B3SR');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (26, 'Toyota Camry Cabin Air Filter', 35, 10, 6, 'AF-TCAM');

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (27, 'Honda Accord Cabin Air Filter', 33, 10, 6, 'AF-HACC');

-- Wipers
INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (28, 'Bosch Wiper Blades Set 22""/20""', 28, 6, 7, NULL);

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (29, 'Denso Wiper Blades Set 24""/18""', 30, 10, 7, NULL);

INSERT INTO listing (listing_id, listing_title, price, brand_id, part_type_id, mpn)
VALUES (30, 'Brembo Performance Brake Pad + Rotor Kit (Corolla)', 260, 5, 1, 'KIT-TCOR-BREMBO');

-------------------------------------------------------
-- LISTING_FITMENT (link every listing to real trims,
-- positions & drives so the view has no null make/model/year/trim)
-------------------------------------------------------
PROMPT === Inserting listing fitment mappings ===

-- 1: Corolla brake pads 2018-2020, FRONT, FWD
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (1, 1, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (1, 2, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (1, 3, 1, 1);

-- 2: Camry pads, FRONT, FWD
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (2, 4, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (2, 5, 1, 1);

-- 3: Civic pads
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (3, 6, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (3, 7, 1, 1);

-- 4: Accord pads
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (4, 8, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (4, 9, 1, 1);

-- 5: F-150 pads, FRONT, 4WD
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (5, 10, 1, 4);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (5, 11, 1, 4);

-- 6: 3 Series pads, FRONT, RWD
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (6, 14, 1, 2);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (6, 15, 1, 2);

-- 7: Silverado pads, FRONT, 4WD
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (7, 17, 1, 4);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (7, 18, 1, 4);

-- 8: Altima pads
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (8, 21, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (8, 22, 1, 1);

-- 9: Elantra pads
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (9, 23, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (9, 24, 1, 1);

-- 10–16: rotors, mirror the pad mappings (front rotors)
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (10, 1, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (10, 2, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (10, 3, 1, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (11, 6, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (11, 7, 1, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (12, 10, 1, 4);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (12, 11, 1, 4);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (13, 14, 1, 2);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (13, 15, 1, 2);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (14, 17, 1, 4);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (14, 18, 1, 4);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (15, 21, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (15, 22, 1, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (16, 23, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (16, 24, 1, 1);

-- 17–20: shocks, rear positions
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (17, 4, 2, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (17, 5, 2, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (18, 8, 2, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (18, 9, 2, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (19, 10, 2, 4);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (19, 11, 2, 4);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (20, 16, 2, 3);

-- 21–22: control arms, front left/right
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (21, 6, 3, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (21, 7, 4, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (22, 1, 3, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (22, 2, 4, 1);

-- 23–27: filters – map to trims with generic FRONT, FWD so columns aren't empty
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (23, 1, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (24, 6, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (25, 14, 1, 2);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (26, 4, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (27, 8, 1, 1);

-- 28–30: wipers / combo kit mapped to multiple trims
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (28, 1, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (28, 4, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (29, 6, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (29, 8, 1, 1);

INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (30, 1, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (30, 2, 1, 1);
INSERT INTO listing_fitment (listing_id, trim_id, position_id, drive_id)
VALUES (30, 3, 1, 1);

COMMIT;

PROMPT === web_demo_seed.sql complete: lookup tables + ~30 listings + rich fitment ===