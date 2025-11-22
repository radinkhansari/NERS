-- trim_make_trigger.sql
-- Auto-populate TRIM.MAKE_ID from MODEL.MAKE_ID on insert

SET SERVEROUTPUT ON

CREATE OR REPLACE TRIGGER trg_trim_set_make
BEFORE INSERT ON trim
FOR EACH ROW
WHEN (NEW.model_id IS NOT NULL AND NEW.make_id IS NULL)
DECLARE
  v_make_id  make.make_id%TYPE;
BEGIN
  -- Look up the make_id from the model table
  SELECT m.make_id
  INTO   v_make_id
  FROM   model m
  WHERE  m.model_id = :NEW.model_id;

  :NEW.make_id := v_make_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- If model_id doesn't exist, raise a clearer error
    RAISE_APPLICATION_ERROR(
      -20001,
      'TRIM insert failed: MODEL_ID ' || :NEW.model_id || ' not found in MODEL table'
    );
END;
/

SHOW ERRORS TRIGGER trg_trim_set_make;

COMMIT;
