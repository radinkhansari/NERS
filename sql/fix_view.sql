-- fix_view.sql
-- Fix View_NormalizedFitment to use listing_fitment bridge table
-- This matches the schema used in web_demo_seed.sql

SET SERVEROUTPUT ON
PROMPT === Fixing View_NormalizedFitment to use listing_fitment table ===

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

PROMPT === View_NormalizedFitment updated to use listing_fitment bridge table ===
PROMPT === The view now properly joins through listing_fitment to get make/model/trim info ===



