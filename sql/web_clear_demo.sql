-- web_clear_demo.sql
-- Clears all Auto-Parts demo data, keeps the tables and constraints.

SET SERVEROUTPUT ON
PROMPT === Clearing Auto-Parts demo data ===

-- Child tables first
DELETE FROM listing;
DELETE FROM parttype_brand;
DELETE FROM trim;
DELETE FROM model;
DELETE FROM part_type;
DELETE FROM brand;
DELETE FROM engine_spec;
DELETE FROM drive_train;
DELETE FROM position;
DELETE FROM make;
DELETE FROM brand_alias;

COMMIT;

PROMPT === web_clear_demo.sql complete (all project tables empty) ===
