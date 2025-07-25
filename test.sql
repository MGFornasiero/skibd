DROP SCHEMA test CASCADE;
CREATE SCHEMA test;
CREATE SEQUENCE test.seq_kihon_id_inventory AS SMALLINT ;
CREATE TABLE test.kihon_inventory(
    id_inventory SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_inventory'),
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    notes TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
);

INSERT INTO staging.kihon_inventory(id_inventory ,grade_id ,number ) VALUES
    ( NULL ,'12' ,'1' ),
    ( 122 ,'12' ,'50' ),
    ( 123 ,'12' ,'3' ),
    ( 124 ,'12' ,'4' ),
    ( 115 ,'12' ,'5' );




-------- Ensure id_inventory is set to nextval for NULL values



CREATE PROCEDURE feed_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update as (UPDATE test.kihon_inventory inv
    SET id_inventory = staging.id_inventory ,
        grade_id = staging.grade_id ,
        number = staging.number ,
        notes = staging.notes 
    FROM staging.kihon_inventory staging
    WHERE inv.id_inventory = staging.id_inventory
    RETURNING inv.id_inventory
),
tbl_update AS (
    INSERT INTO test.kihon_inventory(
        id_inventory,
        grade_id ,
        number ,
        notes 
    )
    SELECT id_inventory,
        grade_id ,
        number ,
        notes
    FROM (SELECT tot.id_inventory ,
        grade_id ,
        number ,
        notes
        FROM staging.kihon_inventory tot
        LEFT JOIN tbl_pk_update esc
        ON tot.id_inventory = esc.id_inventory
        WHERE esc.id_inventory IS NULL)
    ON CONFLICT (grade_id , number) 
    DO UPDATE
    SET id_inventory = EXCLUDED.id_inventory ,
        grade_id = EXCLUDED.grade_id ,
        number = EXCLUDED.number ,
        notes = EXCLUDED.notes 
    RETURNING id_inventory),
details AS (
    SELECT base.id_inventory ,
        pk.id_inventory IS NOT NULL as staging_pk_update,
        upd.id_inventory IS NOT NULL as staging_update
    FROM staging.kihon_inventory AS base
    LEFT JOIN tbl_pk_update AS pk
    ON base.id_inventory = pk.id_inventory
    LEFT JOIN tbl_update AS upd 
    ON base.id_inventory = upd.id_inventory
)

UPDATE staging.kihon_inventory t
SET staging_pk_update = d.staging_pk_update ,
    staging_update = d.staging_update
FROM details d
WHERE t.id_inventory = d.id_inventory
;
END;


