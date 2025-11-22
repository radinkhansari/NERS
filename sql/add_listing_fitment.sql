-- add_listing_fitment.sql
-- Create LISTING_FITMENT table safely

SET SERVEROUTPUT ON

-- Drop existing table if present (safe re-run)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE listing_fitment CASCADE CONSTRAINTS PURGE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

-- Recreate LISTING_FITMENT with a straightforward composite PK
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE listing_fitment (
      listing_id  NUMBER CONSTRAINT nn_lf_listing NOT NULL,
      trim_id     NUMBER CONSTRAINT nn_lf_trim    NOT NULL,
      position_id NUMBER CONSTRAINT nn_lf_pos     NOT NULL,
      drive_id    NUMBER CONSTRAINT nn_lf_drive   NOT NULL,
      CONSTRAINT pk_listing_fitment PRIMARY KEY (listing_id, trim_id, position_id, drive_id),
      CONSTRAINT fk_lf_listing  FOREIGN KEY (listing_id)  REFERENCES listing(listing_id),
      CONSTRAINT fk_lf_trim     FOREIGN KEY (trim_id)     REFERENCES trim(trim_id),
      CONSTRAINT fk_lf_position FOREIGN KEY (position_id) REFERENCES position(position_id),
      CONSTRAINT fk_lf_drive    FOREIGN KEY (drive_id)    REFERENCES drive_train(drive_id)
    )
  ';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
      RAISE;
    END IF;
END;
/

COMMIT;