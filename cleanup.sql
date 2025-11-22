-- =========================================
-- cleanup.sql  (safe to re-run, no errors if empty)
-- =========================================

-- Drop VIEWS (list only the ones you created)
BEGIN
  FOR v IN (
    SELECT view_name
    FROM user_views
    WHERE view_name IN (
      'BRAND_LISTING_SUMMARY',
      'PART_TYPE_POPULARITY',
      'ENGINE_CODE_FREQUENCY'
    )
    -- OR add patterns, e.g.: OR view_name LIKE 'A5\_%' ESCAPE '\'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/
-- If you truly want to drop ALL your views, replace the WHERE clause with "WHERE 1=1".

-- Drop TRIGGERS (optional – only if you created standalone triggers)
BEGIN
  FOR trg IN (
    SELECT trigger_name
    FROM user_triggers
    WHERE table_name IN ('LISTING','PARTTYPE_BRAND','TRIM','PART_TYPE','BRAND','ENGINE_SPEC','DRIVE_TRAIN','POSITION','MAKE')
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TRIGGER ' || trg.trigger_name;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- Drop TABLES (child -> parent) with CASCADE CONSTRAINTS PURGE
BEGIN
  FOR t IN (
    SELECT table_name FROM user_tables
    WHERE table_name IN (
      'LISTING',
      'PARTTYPE_BRAND',
      'TRIM',
      'PART_TYPE',
      'BRAND',
      'ENGINE_SPEC',
      'DRIVE_TRAIN',
      'POSITION',
      'MAKE'
    )
    ORDER BY
      CASE table_name
        WHEN 'LISTING'        THEN 1
        WHEN 'PARTTYPE_BRAND' THEN 2
        WHEN 'TRIM'           THEN 3
        WHEN 'PART_TYPE'      THEN 4
        WHEN 'BRAND'          THEN 5
        WHEN 'ENGINE_SPEC'    THEN 6
        WHEN 'DRIVE_TRAIN'    THEN 7
        WHEN 'POSITION'       THEN 8
        WHEN 'MAKE'           THEN 9
        ELSE 10
      END
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- Drop SEQUENCES (single safe block; OK even if nothing matches)
BEGIN
  FOR s IN (
    SELECT sequence_name
    FROM user_sequences
    WHERE sequence_name IN (
      -- Empty-list-safe via nested table:
      SELECT COLUMN_VALUE
      FROM TABLE(sys.odcivarchar2list(
        -- Add explicit names here if you create any, e.g.:
        -- 'MAKE_SEQ','BRAND_SEQ','PART_TYPE_SEQ','LISTING_SEQ'
      ))
    )
    OR sequence_name LIKE 'MAKE\_%\_SEQ'    ESCAPE '\'
    OR sequence_name LIKE 'BRAND\_%\_SEQ'   ESCAPE '\'
    OR sequence_name LIKE 'PART\_%\_SEQ'    ESCAPE '\'
    OR sequence_name LIKE 'LISTING\_%\_SEQ' ESCAPE '\'
    -- Add more patterns as needed
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- Finally, clear out recycled objects so names are free
PURGE RECYCLEBIN;
