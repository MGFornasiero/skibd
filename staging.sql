DROP SCHEMA staging CASCADE;

CREATE SCHEMA staging;


CREATE TABLE staging.targets(
    id_target SMALLINT UNIQUE,
    name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255),
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    tsv_name tsvector GENERATED ALWAYS AS (to_tsvector('simple',name)) STORED,
    tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple',description)) STORED,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_targetname UNIQUE(name)
); -- parti del corpo colpite

CREATE TABLE staging.strikingparts( 
    id_part SMALLINT UNIQUE,
    name VARCHAR(255) NOT NULL,
    translation VARCHAR(255),
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    tsv_name tsvector GENERATED ALWAYS AS (to_tsvector('simple',name) || to_tsvector('simple',translation)) STORED,
    tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple',description)) STORED,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_strikingpartsname UNIQUE(name)
); -- parti del corpo che colpiscono

CREATE TABLE staging.technics(
    id_technic SMALLINT UNIQUE DEFAULT,
    waza staging.waza_type,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) ,
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    tsv_name tsvector GENERATED ALWAYS AS (to_tsvector('simple',name)) STORED,
    tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple',description)) STORED,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_technicname UNIQUE(name)
); --Inventario delle tecniche

CREATE TABLE staging.stands(
    id_stand SMALLINT UNIQUE,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) , -- altoro nome con la quale è conosciuta
    description TEXT,
    illustration_url TEXT,
    notes TEXT,
    tsv_name tsvector GENERATED ALWAYS AS (to_tsvector('simple',name)) STORED,
    tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple',description)) STORED,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_standname UNIQUE(name)
); --Inventario delle posizioni

CREATE TABLE staging.grades(
    id_grade SMALLINT UNIQUE,
    gtype staging.grade_type NOT NULL,
    grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
    color staging.beltcolor,
    CONSTRAINT unique_grade UNIQUE (gtype, grade)
); -- forma normale della sequenza di gradi Kiu e Dan

CREATE TABLE staging.kihon_inventory(
    id_inventory SMALLINT ,
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    notes TEXT,
    staging_id BOOL,
    staging_pk_update BOOL,
    staging_update BOOL ,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
);

CREATE TABLE staging.kihon_sequences(
    id_sequence SMALLINT UNIQUE ,
    inventory_id SMALLINT NOT NULL REFERENCES ski.kihon_inventory(id_inventory),
    seq_num SMALLINT NOT NULL, 
    stand SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
    techinc SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
    gyaku bool DEFAULT 'false',
    target_hgt ski.target_hgt ,
    notes TEXT ,
    resource_url TEXT,
    CONSTRAINT unique_kihonsequence UNIQUE (inventory_id, seq_num)
);

CREATE TABLE staging.kihon_tx(
    id_tx SMALLINT UNIQUE ,
    from_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence), 
    to_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    movement ski.movements ,
    notes TEXT,
    tempo ski.tempo ,
    resource_url TEXT,
    CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
); 

CREATE TABLE staging.Kata_inventory(
    id_kata SMALLINT UNIQUE,
    kata VARCHAR(255) NOT NULL,
    serie ski.kata_series,
    starting_leg ski.sides NOT NULL,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata UNIQUE (kata)
);

CREATE TABLE staging.kata_sequence(
    id_sequence SMALLINT UNIQUE  ,
    kata_id SMALLINT NOT NULL REFERENCES ski.Kata_inventory(id_kata),
    seq_num SMALLINT NOT NULL,
    stand_id SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
    speed ski.tempo ,
    side ski.sides, 
    embusen ski.embusen_points ,
    facing ski.absolute_directions, 
    kiai bool,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata_seq UNIQUE (kata_id, seq_num)
); 

CREATE TABLE staging.kata_sequence_waza (
    id_kswaza SMALLINT UNIQUE ,
    sequence_id SMALLINT REFERENCES ski.kata_sequence(id_sequence),
    arto ski.arti,
    technic_id SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
    strikingpart_id SMALLINT REFERENCES ski.strikingparts(id_part),
    technic_target_id SMALLINT REFERENCES ski.targets(id_target),
    notes TEXT
);

CREATE TABLE staging.kata_tx (
    id_tx SMALLINT UNIQUE ,
    from_seq SMALLINT NOT NULL ,
    to_seq SMALLINT NOT NULL ,
    tempo ski.tempo ,
    direction ski.sides ,
    intermediate_stand SMALLINT REFERENCES ski.stands(id_stand),
    notes TEXT,
    resource_url TEXT
);


CREATE OR REPLACE FUNCTION staging.floor_id_targets()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_target AS id FROM ski.targets
    UNION 
    SELECT id_target AS id FROM staging.targets
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_strikingparts()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_part AS id FROM ski.strikingparts
    UNION 
    SELECT id_part AS id FROM staging.strikingparts
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_technics()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_technic AS id FROM ski.technics
    UNION 
    SELECT id_technic AS id FROM staging.technics
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_stands()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_stand AS id FROM ski.stands
    UNION 
    SELECT id_stand AS id FROM staging.stands
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_grades()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_grade AS id FROM ski.grades
    UNION 
    SELECT id_grade AS id FROM staging.grades
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_inventory()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_inventory AS id FROM ski.kihon_inventory
    UNION 
    SELECT id_inventory AS id FROM staging.kihon_inventory
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_sequences()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_sequence AS id FROM ski.kihon_sequences
    UNION 
    SELECT id_sequence AS id FROM staging.kihon_sequences
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_tx()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_tx AS id FROM ski.kihon_tx
    UNION 
    SELECT id_tx AS id FROM staging.kihon_tx
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_kata()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_kata AS id FROM ski.Kata_inventory
    UNION 
    SELECT id_kata AS id FROM staging.Kata_inventory
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_kata_sequence()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_sequence AS id FROM ski.kata_sequence
    UNION 
    SELECT id_sequence AS id FROM staging.kata_sequence
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_kswaza()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_kswaza AS id FROM ski.kata_sequence_waza
    UNION 
    SELECT id_kswaza AS id FROM staging.kata_sequence_waza
    );
$func$;

CREATE OR REPLACE FUNCTION staging.floor_id_kata_tx()
  RETURNS integer
  LANGUAGE sql AS
$func$
  SELECT MAX(id) FROM (
    SELECT id_tx AS id FROM ski.kata_tx
    UNION 
    SELECT id_tx AS id FROM staging.kata_tx
    );
$func$;
---

CREATE PROCEDURE fill_targets()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.targets
    SET id_target = nextval('ski.seq_id_target')
    WHERE id_target IS NULL
    RETURNING id_target
)
UPDATE staging.targets
SET staging_id = true
FROM assign_id
WHERE targets.id_target = assign_id.id_target;

UPDATE staging.targets
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_strikingparts()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.strikingparts
    SET id_part = nextval('ski.seq_id_part')
    WHERE id_part IS NULL
    RETURNING id_part
)
UPDATE staging.strikingparts
SET staging_id = true
FROM assign_id
WHERE strikingparts.id_part = assign_id.id_part;

UPDATE staging.strikingparts
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_technics()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.technics
    SET id_technic = nextval('ski.seq_id_technic')
    WHERE id_technic IS NULL
    RETURNING id_technic
)
UPDATE staging.technics
SET staging_id = true
FROM assign_id
WHERE technics.id_technic = assign_id.id_technic;

UPDATE staging.technics
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_stands()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.stands
    SET id_stand = nextval('ski.seq_id_stand')
    WHERE id_stand IS NULL
    RETURNING id_stand
)
UPDATE staging.stands
SET staging_id = true
FROM assign_id
WHERE stands.id_stand = assign_id.id_stand;

UPDATE staging.stands
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_grades()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.grades
    SET id_grade = nextval('ski.seq_id_grade')
    WHERE id_grade IS NULL
    RETURNING id_grade
)
UPDATE staging.grades
SET staging_id = true
FROM assign_id
WHERE grades.id_grade = assign_id.id_grade;

UPDATE staging.grades
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kihon_inventory
    SET id_inventory = nextval('ski.seq_kihon_id_inventory')
    WHERE id_inventory IS NULL
    RETURNING id_inventory
)
UPDATE staging.kihon_inventory
SET staging_id = true
FROM assign_id
WHERE kihon_inventory.id_inventory = assign_id.id_inventory;

UPDATE staging.kihon_inventory
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kihon_sequences()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kihon_sequences
    SET id_sequence = nextval('ski.seq_kihon_id_sequence')
    WHERE id_sequence IS NULL
    RETURNING id_sequence
)
UPDATE staging.kihon_sequences
SET staging_id = true
FROM assign_id
WHERE kihon_sequences.id_sequence = assign_id.id_sequence;

UPDATE staging.kihon_sequences
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kihon_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kihon_tx
    SET id_tx = nextval('ski.seq_kihon_id_tx')
    WHERE id_tx IS NULL
    RETURNING id_tx
)
UPDATE staging.kihon_tx
SET staging_id = true
FROM assign_id
WHERE kihon_tx.id_tx = assign_id.id_tx;

UPDATE staging.kihon_tx
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_Kata_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.Kata_inventory
    SET id_kata = nextval('ski.seq_kata_id_kata')
    WHERE id_kata IS NULL
    RETURNING id_kata
)
UPDATE staging.Kata_inventory
SET staging_id = true
FROM assign_id
WHERE Kata_inventory.id_kata = assign_id.id_kata;

UPDATE staging.Kata_inventory
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kata_sequence()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kata_sequence
    SET id_sequence = nextval('ski.seq_kata_id_sequence')
    WHERE id_sequence IS NULL
    RETURNING id_sequence
)
UPDATE staging.kata_sequence
SET staging_id = true
FROM assign_id
WHERE kata_sequence.id_sequence = assign_id.id_sequence;

UPDATE staging.kata_sequence
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kata_sequence_waza()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kata_sequence_waza
    SET id_kswaza = nextval('ski.seq_kata_id_kswaza')
    WHERE id_kswaza IS NULL
    RETURNING id_kswaza
)
UPDATE staging.kata_sequence_waza
SET staging_id = true
FROM assign_id
WHERE kata_sequence_waza.id_kswaza = assign_id.id_kswaza;

UPDATE staging.kata_sequence_waza
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE fill_kata_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH assign_id AS (
    UPDATE staging.kata_tx
    SET id_tx = nextval('ski.seq_kata_id_tx')
    WHERE id_tx IS NULL
    RETURNING id_tx
)
UPDATE staging.kata_tx
SET staging_id = true
FROM assign_id
WHERE kata_tx.id_tx = assign_id.id_tx;

UPDATE staging.kata_tx
SET staging_id = false
WHERE staging_id IS NULL;
END;

CREATE PROCEDURE feed_targets()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.targets t
    SET id_target = staging.id_target,
        name = staging.name,
        original_name = staging.original_name,
        description = staging.description,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.targets staging
    WHERE t.id_target = staging.id_target
    RETURNING t.id_target
),
tbl_update AS (
    INSERT INTO test.targets(
        id_target, name, original_name, description, notes, resource_url
    )
    SELECT id_target, name, original_name, description, notes, resource_url
    FROM (
        SELECT tot.id_target, name, original_name, description, notes, resource_url
        FROM staging.targets tot
        LEFT JOIN tbl_pk_update esc ON tot.id_target = esc.id_target
        WHERE esc.id_target IS NULL
    )
    ON CONFLICT (name)
    DO UPDATE SET
        id_target = EXCLUDED.id_target,
        name = EXCLUDED.name,
        original_name = EXCLUDED.original_name,
        description = EXCLUDED.description,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_target
),
details AS (
    SELECT base.id_target,
        pk.id_target IS NOT NULL AS staging_pk_update,
        upd.id_target IS NOT NULL AS staging_update
    FROM staging.targets AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_target = pk.id_target
    LEFT JOIN tbl_update AS upd ON base.id_target = upd.id_target
)
UPDATE staging.targets t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_target = d.id_target;
END;

CREATE PROCEDURE feed_strikingparts()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.strikingparts t
    SET id_part = staging.id_part,
        name = staging.name,
        translation = staging.translation,
        description = staging.description,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.strikingparts staging
    WHERE t.id_part = staging.id_part
    RETURNING t.id_part
),
tbl_update AS (
    INSERT INTO test.strikingparts(
        id_part, name, translation, description, notes, resource_url
    )
    SELECT id_part, name, translation, description, notes, resource_url
    FROM (
        SELECT tot.id_part, name, translation, description, notes, resource_url
        FROM staging.strikingparts tot
        LEFT JOIN tbl_pk_update esc ON tot.id_part = esc.id_part
        WHERE esc.id_part IS NULL
    )
    ON CONFLICT (name)
    DO UPDATE SET
        id_part = EXCLUDED.id_part,
        name = EXCLUDED.name,
        translation = EXCLUDED.translation,
        description = EXCLUDED.description,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_part
),
details AS (
    SELECT base.id_part,
        pk.id_part IS NOT NULL AS staging_pk_update,
        upd.id_part IS NOT NULL AS staging_update
    FROM staging.strikingparts AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_part = pk.id_part
    LEFT JOIN tbl_update AS upd ON base.id_part = upd.id_part
)
UPDATE staging.strikingparts t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_part = d.id_part;
END;

CREATE PROCEDURE feed_technics()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.technics t
    SET id_technic = staging.id_technic,
        waza = staging.waza,
        name = staging.name,
        description = staging.description,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.technics staging
    WHERE t.id_technic = staging.id_technic
    RETURNING t.id_technic
),
tbl_update AS (
    INSERT INTO test.technics(
        id_technic, waza, name, description, notes, resource_url
    )
    SELECT id_technic, waza, name, description, notes, resource_url
    FROM (
        SELECT tot.id_technic, waza, name, description, notes, resource_url
        FROM staging.technics tot
        LEFT JOIN tbl_pk_update esc ON tot.id_technic = esc.id_technic
        WHERE esc.id_technic IS NULL
    )
    ON CONFLICT (name)
    DO UPDATE SET
        id_technic = EXCLUDED.id_technic,
        waza = EXCLUDED.waza,
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_technic
),
details AS (
    SELECT base.id_technic,
        pk.id_technic IS NOT NULL AS staging_pk_update,
        upd.id_technic IS NOT NULL AS staging_update
    FROM staging.technics AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_technic = pk.id_technic
    LEFT JOIN tbl_update AS upd ON base.id_technic = upd.id_technic
)
UPDATE staging.technics t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_technic = d.id_technic;
END;

CREATE PROCEDURE feed_stands()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.stands t
    SET id_stand = staging.id_stand,
        name = staging.name,
        description = staging.description,
        illustration_url = staging.illustration_url,
        notes = staging.notes
    FROM staging.stands staging
    WHERE t.id_stand = staging.id_stand
    RETURNING t.id_stand
),
tbl_update AS (
    INSERT INTO test.stands(
        id_stand, name, description, illustration_url, notes
    )
    SELECT id_stand, name, description, illustration_url, notes
    FROM (
        SELECT tot.id_stand, name, description, illustration_url, notes
        FROM staging.stands tot
        LEFT JOIN tbl_pk_update esc ON tot.id_stand = esc.id_stand
        WHERE esc.id_stand IS NULL
    )
    ON CONFLICT (name)
    DO UPDATE SET
        id_stand = EXCLUDED.id_stand,
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        illustration_url = EXCLUDED.illustration_url,
        notes = EXCLUDED.notes
    RETURNING id_stand
),
details AS (
    SELECT base.id_stand,
        pk.id_stand IS NOT NULL AS staging_pk_update,
        upd.id_stand IS NOT NULL AS staging_update
    FROM staging.stands AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_stand = pk.id_stand
    LEFT JOIN tbl_update AS upd ON base.id_stand = upd.id_stand
)
UPDATE staging.stands t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_stand = d.id_stand;
END;

CREATE PROCEDURE feed_grades()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.grades t
    SET id_grade = staging.id_grade,
        gtype = staging.gtype,
        grade = staging.grade,
        color = staging.color
    FROM staging.grades staging
    WHERE t.id_grade = staging.id_grade
    RETURNING t.id_grade
),
tbl_update AS (
    INSERT INTO test.grades(
        id_grade, gtype, grade, color
    )
    SELECT id_grade, gtype, grade, color
    FROM (
        SELECT tot.id_grade, gtype, grade, color
        FROM staging.grades tot
        LEFT JOIN tbl_pk_update esc ON tot.id_grade = esc.id_grade
        WHERE esc.id_grade IS NULL
    )
    ON CONFLICT (gtype, grade)
    DO UPDATE SET
        id_grade = EXCLUDED.id_grade,
        gtype = EXCLUDED.gtype,
        grade = EXCLUDED.grade,
        color = EXCLUDED.color
    RETURNING id_grade
),
details AS (
    SELECT base.id_grade,
        pk.id_grade IS NOT NULL AS staging_pk_update,
        upd.id_grade IS NOT NULL AS staging_update
    FROM staging.grades AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_grade = pk.id_grade
    LEFT JOIN tbl_update AS upd ON base.id_grade = upd.id_grade
)
UPDATE staging.grades t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_grade = d.id_grade;
END;

CREATE PROCEDURE feed_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kihon_inventory inv
    SET id_inventory = staging.id_inventory,
        grade_id = staging.grade_id,
        number = staging.number,
        notes = staging.notes
    FROM staging.kihon_inventory staging
    WHERE inv.id_inventory = staging.id_inventory
    RETURNING inv.id_inventory
),
tbl_update AS (
    INSERT INTO test.kihon_inventory(
        id_inventory, grade_id, number, notes
    )
    SELECT id_inventory, grade_id, number, notes
    FROM (
        SELECT tot.id_inventory, grade_id, number, notes
        FROM staging.kihon_inventory tot
        LEFT JOIN tbl_pk_update esc ON tot.id_inventory = esc.id_inventory
        WHERE esc.id_inventory IS NULL
    )
    ON CONFLICT (grade_id, number)
    DO UPDATE SET
        id_inventory = EXCLUDED.id_inventory,
        grade_id = EXCLUDED.grade_id,
        number = EXCLUDED.number,
        notes = EXCLUDED.notes
    RETURNING id_inventory
),
details AS (
    SELECT base.id_inventory,
        pk.id_inventory IS NOT NULL AS staging_pk_update,
        upd.id_inventory IS NOT NULL AS staging_update
    FROM staging.kihon_inventory AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_inventory = pk.id_inventory
    LEFT JOIN tbl_update AS upd ON base.id_inventory = upd.id_inventory
)
UPDATE staging.kihon_inventory t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_inventory = d.id_inventory;
END;

CREATE PROCEDURE feed_kihon_sequences()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kihon_sequences seq
    SET id_sequence = staging.id_sequence,
        inventory_id = staging.inventory_id,
        seq_num = staging.seq_num,
        stand = staging.stand,
        techinc = staging.techinc,
        gyaku = staging.gyaku,
        target_hgt = staging.target_hgt,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.kihon_sequences staging
    WHERE seq.id_sequence = staging.id_sequence
    RETURNING seq.id_sequence
),
tbl_update AS (
    INSERT INTO test.kihon_sequences(
        id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
    )
    SELECT id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
    FROM (
        SELECT tot.id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
        FROM staging.kihon_sequences tot
        LEFT JOIN tbl_pk_update esc ON tot.id_sequence = esc.id_sequence
        WHERE esc.id_sequence IS NULL
    )
    ON CONFLICT (inventory_id, seq_num)
    DO UPDATE SET
        id_sequence = EXCLUDED.id_sequence,
        inventory_id = EXCLUDED.inventory_id,
        seq_num = EXCLUDED.seq_num,
        stand = EXCLUDED.stand,
        techinc = EXCLUDED.techinc,
        gyaku = EXCLUDED.gyaku,
        target_hgt = EXCLUDED.target_hgt,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_sequence
),
details AS (
    SELECT base.id_sequence,
        pk.id_sequence IS NOT NULL AS staging_pk_update,
        upd.id_sequence IS NOT NULL AS staging_update
    FROM staging.kihon_sequences AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_sequence = pk.id_sequence
    LEFT JOIN tbl_update AS upd ON base.id_sequence = upd.id_sequence
)
UPDATE staging.kihon_sequences t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_sequence = d.id_sequence;
END;

CREATE PROCEDURE feed_kihon_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kihon_tx tx
    SET id_tx = staging.id_tx,
        from_seq = staging.from_seq,
        to_seq = staging.to_seq,
        movement = staging.movement,
        notes = staging.notes,
        tempo = staging.tempo,
        resource_url = staging.resource_url
    FROM staging.kihon_tx staging
    WHERE tx.id_tx = staging.id_tx
    RETURNING tx.id_tx
),
tbl_update AS (
    INSERT INTO test.kihon_tx(
        id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
    )
    SELECT id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
    FROM (
        SELECT tot.id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
        FROM staging.kihon_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
    )
    ON CONFLICT (from_seq, to_seq)
    DO UPDATE SET
        id_tx = EXCLUDED.id_tx,
        from_seq = EXCLUDED.from_seq,
        to_seq = EXCLUDED.to_seq,
        movement = EXCLUDED.movement,
        notes = EXCLUDED.notes,
        tempo = EXCLUDED.tempo,
        resource_url = EXCLUDED.resource_url
    RETURNING id_tx
),
details AS (
    SELECT base.id_tx,
        pk.id_tx IS NOT NULL AS staging_pk_update,
        upd.id_tx IS NOT NULL AS staging_update
    FROM staging.kihon_tx AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_tx = pk.id_tx
    LEFT JOIN tbl_update AS upd ON base.id_tx = upd.id_tx
)
UPDATE staging.kihon_tx t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_tx = d.id_tx;
END;

CREATE PROCEDURE feed_Kata_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.Kata_inventory kata
    SET id_kata = staging.id_kata,
        kata = staging.kata,
        serie = staging.serie,
        starting_leg = staging.starting_leg,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.Kata_inventory staging
    WHERE kata.id_kata = staging.id_kata
    RETURNING kata.id_kata
),
tbl_update AS (
    INSERT INTO test.Kata_inventory(
        id_kata, kata, serie, starting_leg, notes, resource_url
    )
    SELECT id_kata, kata, serie, starting_leg, notes, resource_url
    FROM (
        SELECT tot.id_kata, kata, serie, starting_leg, notes, resource_url
        FROM staging.Kata_inventory tot
        LEFT JOIN tbl_pk_update esc ON tot.id_kata = esc.id_kata
        WHERE esc.id_kata IS NULL
    )
    ON CONFLICT (kata)
    DO UPDATE SET
        id_kata = EXCLUDED.id_kata,
        kata = EXCLUDED.kata,
        serie = EXCLUDED.serie,
        starting_leg = EXCLUDED.starting_leg,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_kata
),
details AS (
    SELECT base.id_kata,
        pk.id_kata IS NOT NULL AS staging_pk_update,
        upd.id_kata IS NOT NULL AS staging_update
    FROM staging.Kata_inventory AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_kata = pk.id_kata
    LEFT JOIN tbl_update AS upd ON base.id_kata = upd.id_kata
)
UPDATE staging.Kata_inventory t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_kata = d.id_kata;
END;

CREATE PROCEDURE feed_kata_sequence()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kata_sequence seq
    SET id_sequence = staging.id_sequence,
        kata_id = staging.kata_id,
        seq_num = staging.seq_num,
        stand_id = staging.stand_id,
        speed = staging.speed,
        side = staging.side,
        embusen = staging.embusen,
        facing = staging.facing,
        kiai = staging.kiai,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.kata_sequence staging
    WHERE seq.id_sequence = staging.id_sequence
    RETURNING seq.id_sequence
),
tbl_update AS (
    INSERT INTO test.kata_sequence(
        id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
    )
    SELECT id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
    FROM (
        SELECT tot.id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
        FROM staging.kata_sequence tot
        LEFT JOIN tbl_pk_update esc ON tot.id_sequence = esc.id_sequence
        WHERE esc.id_sequence IS NULL
    )
    ON CONFLICT (kata_id, seq_num)
    DO UPDATE SET
        id_sequence = EXCLUDED.id_sequence,
        kata_id = EXCLUDED.kata_id,
        seq_num = EXCLUDED.seq_num,
        stand_id = EXCLUDED.stand_id,
        speed = EXCLUDED.speed,
        side = EXCLUDED.side,
        embusen = EXCLUDED.embusen,
        facing = EXCLUDED.facing,
        kiai = EXCLUDED.kiai,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_sequence
),
details AS (
    SELECT base.id_sequence,
        pk.id_sequence IS NOT NULL AS staging_pk_update,
        upd.id_sequence IS NOT NULL AS staging_update
    FROM staging.kata_sequence AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_sequence = pk.id_sequence
    LEFT JOIN tbl_update AS upd ON base.id_sequence = upd.id_sequence
)
UPDATE staging.kata_sequence t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_sequence = d.id_sequence;
END;

CREATE PROCEDURE feed_kata_sequence_waza()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kata_sequence_waza waza
    SET id_kswaza = staging.id_kswaza,
        sequence_id = staging.sequence_id,
        arto = staging.arto,
        technic_id = staging.technic_id,
        strikingpart_id = staging.strikingpart_id,
        technic_target_id = staging.technic_target_id,
        notes = staging.notes
    FROM staging.kata_sequence_waza staging
    WHERE waza.id_kswaza = staging.id_kswaza
    RETURNING waza.id_kswaza
),
tbl_update AS (
    INSERT INTO test.kata_sequence_waza(
        id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
    )
    SELECT id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
    FROM (
        SELECT tot.id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
        FROM staging.kata_sequence_waza tot
        LEFT JOIN tbl_pk_update esc ON tot.id_kswaza = esc.id_kswaza
        WHERE esc.id_kswaza IS NULL
    )
    ON CONFLICT (id_kswaza)
    DO UPDATE SET
        id_kswaza = EXCLUDED.id_kswaza,
        sequence_id = EXCLUDED.sequence_id,
        arto = EXCLUDED.arto,
        technic_id = EXCLUDED.technic_id,
        strikingpart_id = EXCLUDED.strikingpart_id,
        technic_target_id = EXCLUDED.technic_target_id,
        notes = EXCLUDED.notes
    RETURNING id_kswaza
),
details AS (
    SELECT base.id_kswaza,
        pk.id_kswaza IS NOT NULL AS staging_pk_update,
        upd.id_kswaza IS NOT NULL AS staging_update
    FROM staging.kata_sequence_waza AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_kswaza = pk.id_kswaza
    LEFT JOIN tbl_update AS upd ON base.id_kswaza = upd.id_kswaza
)
UPDATE staging.kata_sequence_waza t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_kswaza = d.id_kswaza;
END;

CREATE PROCEDURE feed_kata_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE test.kata_tx tx
    SET id_tx = staging.id_tx,
        from_seq = staging.from_seq,
        to_seq = staging.to_seq,
        tempo = staging.tempo,
        direction = staging.direction,
        intermediate_stand = staging.intermediate_stand,
        notes = staging.notes,
        resource_url = staging.resource_url
    FROM staging.kata_tx staging
    WHERE tx.id_tx = staging.id_tx
    RETURNING tx.id_tx
),
tbl_update AS (
    INSERT INTO test.kata_tx(
        id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
    )
    SELECT id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
    FROM (
        SELECT tot.id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
        FROM staging.kata_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
    )
    ON CONFLICT (id_tx)
    DO UPDATE SET
        id_tx = EXCLUDED.id_tx,
        from_seq = EXCLUDED.from_seq,
        to_seq = EXCLUDED.to_seq,
        tempo = EXCLUDED.tempo,
        direction = EXCLUDED.direction,
        intermediate_stand = EXCLUDED.intermediate_stand,
        notes = EXCLUDED.notes,
        resource_url = EXCLUDED.resource_url
    RETURNING id_tx
),
details AS (
    SELECT base.id_tx,
        pk.id_tx IS NOT NULL AS staging_pk_update,
        upd.id_tx IS NOT NULL AS staging_update
    FROM staging.kata_tx AS base
    LEFT JOIN tbl_pk_update AS pk ON base.id_tx = pk.id_tx
    LEFT JOIN tbl_update AS upd ON base.id_tx = upd.id_tx
)
UPDATE staging.kata_tx t
SET staging_pk_update = d.staging_pk_update,
    staging_update = d.staging_update
FROM details d
WHERE t.id_tx = d.id_tx;
END;