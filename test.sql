
INSERT INTO staging.kihon_inventory(id_inventory ,grade_id ,number ) VALUES
    ( NULL ,'12' ,'1' ),
    ( 122 ,'12' ,'50' ),
    ( 123 ,'12' ,'3' ),
    ( 124 ,'12' ,'4' ),
    ( 115 ,'12' ,'5' );



DELETE FROM test.kihon_inventory
USING staging.kihon_inventory
WHERE test.kihon_inventory.id_inventory = staging.kihon_inventory.id_inventory;

UPDATE test.kihon_inventory inv
SET id_inventory = staging.id_inventory ,
    grade_id = staging.grade_id ,
    number = staging.number ,
    notes = staging.notes 
FROM staging.kihon_inventory staging
WHERE inv.id_inventory = staging.id_inventory;


WITH 
updated as (UPDATE test.kihon_inventory inv
SET id_inventory = staging.id_inventory ,
    grade_id = staging.grade_id ,
    number = staging.number ,
    notes = staging.notes 
FROM staging.kihon_inventory staging
WHERE inv.id_inventory = staging.id_inventory
RETURNING inv.id_inventory)

INSERT INTO test.kihon_inventory(
    id_inventory,
    grade_id ,
    number ,
    notes 
)
SELECT CASE WHEN id_inventory is not NULL THEN id_inventory
        ELSE nextval(pg_get_serial_sequence('test.kihon_inventory','id_inventory'))
        END AS id_inventory,
    grade_id ,
    number ,
    notes
FROM (SELECT tot.id_inventory ,
    grade_id ,
    number ,
    notes
    FROM staging.kihon_inventory tot
    LEFT JOIN updated esc
    ON tot.id_inventory = esc.id_inventory
    WHERE esc.id_inventory IS NULL)
ON CONFLICT (grade_id , number) 
DO UPDATE
SET id_inventory = EXCLUDED.id_inventory ,
    grade_id = EXCLUDED.grade_id ,
    number = EXCLUDED.number ,
    notes = EXCLUDED.notes 
RETURNING *
;


