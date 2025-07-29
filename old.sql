
-- Returns the maximum id_target from ski.targets and staging.targets
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

-- Returns the maximum id_part from ski.strikingparts and staging.strikingparts
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

-- Returns the maximum id_technic from ski.technics and staging.technics
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

-- Returns the maximum id_stand from ski.stands and staging.stands
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

-- Returns the maximum id_grade from ski.grades and staging.grades
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

-- Returns the maximum id_inventory from ski.kihon_inventory and staging.kihon_inventory
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

-- Returns the maximum id_sequence from ski.kihon_sequences and staging.kihon_sequences
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

-- Returns the maximum id_tx from ski.kihon_tx and staging.kihon_tx
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

-- Returns the maximum id_kata from ski.Kata_inventory and staging.Kata_inventory
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

-- Returns the maximum id_sequence from ski.kata_sequence and staging.kata_sequence
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

-- Returns the maximum id_kswaza from ski.kata_sequence_waza and staging.kata_sequence_waza
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

-- Returns the maximum id_tx from ski.kata_tx and staging.kata_tx
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

-- Assigns missing id_target values and sets staging_autoid for staging.targets
CREATE PROCEDURE staging.fill_targets()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.targets
        SET id_target = nextval('ski.seq_id_target')
        WHERE id_target IS NULL
        RETURNING id_target
    )
    UPDATE staging.targets
    SET staging_autoid = true
    FROM assign_id
    WHERE targets.id_target = assign_id.id_target;

    UPDATE staging.targets
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_part values and sets staging_autoid for staging.strikingparts
CREATE PROCEDURE staging.fill_strikingparts()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.strikingparts
        SET id_part = nextval('ski.seq_id_part')
        WHERE id_part IS NULL
        RETURNING id_part
    )
    UPDATE staging.strikingparts
    SET staging_autoid = true
    FROM assign_id
    WHERE strikingparts.id_part = assign_id.id_part;

    UPDATE staging.strikingparts
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_technic values and sets staging_autoid for staging.technics
CREATE PROCEDURE staging.fill_technics()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.technics
        SET id_technic = nextval('ski.seq_id_technic')
        WHERE id_technic IS NULL
        RETURNING id_technic
    )
    UPDATE staging.technics
    SET staging_autoid = true
    FROM assign_id
    WHERE technics.id_technic = assign_id.id_technic;

    UPDATE staging.technics
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_stand values and sets staging_autoid for staging.stands
CREATE PROCEDURE staging.fill_stands()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.stands
        SET id_stand = nextval('ski.seq_id_stand')
        WHERE id_stand IS NULL
        RETURNING id_stand
    )
    UPDATE staging.stands
    SET staging_autoid = true
    FROM assign_id
    WHERE stands.id_stand = assign_id.id_stand;

    UPDATE staging.stands
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_grade values and sets staging_autoid for staging.grades
CREATE PROCEDURE staging.fill_grades()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.grades
        SET id_grade = nextval('ski.seq_id_grade')
        WHERE id_grade IS NULL
        RETURNING id_grade
    )
    UPDATE staging.grades
    SET staging_autoid = true
    FROM assign_id
    WHERE grades.id_grade = assign_id.id_grade;

    UPDATE staging.grades
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_inventory values and sets staging_autoid for staging.kihon_inventory
CREATE PROCEDURE staging.fill_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kihon_inventory
        SET id_inventory = nextval('ski.seq_kihon_id_inventory')
        WHERE id_inventory IS NULL
        RETURNING id_inventory
    )
    UPDATE staging.kihon_inventory
    SET staging_autoid = true
    FROM assign_id
    WHERE kihon_inventory.id_inventory = assign_id.id_inventory;

    UPDATE staging.kihon_inventory
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_sequence values and sets staging_autoid for staging.kihon_sequences
CREATE PROCEDURE staging.fill_kihon_sequences()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kihon_sequences
        SET id_sequence = nextval('ski.seq_kihon_id_sequence')
        WHERE id_sequence IS NULL
        RETURNING id_sequence
    )
    UPDATE staging.kihon_sequences
    SET staging_autoid = true
    FROM assign_id
    WHERE kihon_sequences.id_sequence = assign_id.id_sequence;

    UPDATE staging.kihon_sequences
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_tx values and sets staging_autoid for staging.kihon_tx
CREATE PROCEDURE staging.fill_kihon_tx()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kihon_tx
        SET id_tx = nextval('ski.seq_kihon_id_tx')
        WHERE id_tx IS NULL
        RETURNING id_tx
    )
    UPDATE staging.kihon_tx
    SET staging_autoid = true
    FROM assign_id
    WHERE kihon_tx.id_tx = assign_id.id_tx;

    UPDATE staging.kihon_tx
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_kata values and sets staging_autoid for staging.Kata_inventory
CREATE PROCEDURE staging.fill_Kata_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.Kata_inventory
        SET id_kata = nextval('ski.seq_kata_id_kata')
        WHERE id_kata IS NULL
        RETURNING id_kata
    )
    UPDATE staging.Kata_inventory
    SET staging_autoid = true
    FROM assign_id
    WHERE Kata_inventory.id_kata = assign_id.id_kata;

    UPDATE staging.Kata_inventory
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_sequence values and sets staging_autoid for staging.kata_sequence
CREATE PROCEDURE staging.fill_kata_sequence()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kata_sequence
        SET id_sequence = nextval('ski.seq_kata_id_sequence')
        WHERE id_sequence IS NULL
        RETURNING id_sequence
    )
    UPDATE staging.kata_sequence
    SET staging_autoid = true
    FROM assign_id
    WHERE kata_sequence.id_sequence = assign_id.id_sequence;

    UPDATE staging.kata_sequence
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_kswaza values and sets staging_autoid for staging.kata_sequence_waza
CREATE PROCEDURE staging.fill_kata_sequence_waza()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kata_sequence_waza
        SET id_kswaza = nextval('ski.seq_kata_id_kswaza')
        WHERE id_kswaza IS NULL
        RETURNING id_kswaza
    )
    UPDATE staging.kata_sequence_waza
    SET staging_autoid = true
    FROM assign_id
    WHERE kata_sequence_waza.id_kswaza = assign_id.id_kswaza;

    UPDATE staging.kata_sequence_waza
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Assigns missing id_tx values and sets staging_autoid for staging.kata_tx
CREATE PROCEDURE staging.fill_kata_tx()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH assign_id AS (
        UPDATE staging.kata_tx
        SET id_tx = nextval('ski.seq_kata_id_tx')
        WHERE id_tx IS NULL
        RETURNING id_tx
    )
    UPDATE staging.kata_tx
    SET staging_autoid = true
    FROM assign_id
    WHERE kata_tx.id_tx = assign_id.id_tx;

    UPDATE staging.kata_tx
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;
END;

-- Checks FK for kihon_inventory and moves invalid rows to reject.kihon_inventory
CREATE PROCEDURE staging.chkfk_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_inventory
        FROM staging.kihon_inventory l
        LEFT JOIN staging.dom_grades r
        ON l.grade_id = r.id_grade
        WHERE r.id_grade IS NULL
      )
    UPDATE staging.kihon_inventory t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_inventory = fk.id_inventory;

END;

-- Checks FK for kihon_sequences and moves invalid rows to reject.kihon_sequences
CREATE PROCEDURE staging.chkfk_kihon_sequences()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_sequence
        FROM staging.kihon_sequences l
        LEFT JOIN staging.dom_kihon_inventory ki ON l.inventory_id = ki.id_inventory
        LEFT JOIN staging.dom_stands s ON l.stand = s.id_stand
        LEFT JOIN staging.dom_technics te ON l.techinc = te.id_technic
        WHERE ki.id_inventory IS NULL OR s.id_stand IS NULL OR te.id_technic IS NULL
      )
    UPDATE staging.kihon_sequences t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_sequence = fk.id_sequence;

END;

-- Checks FK for kihon_tx and moves invalid rows to reject.kihon_tx
CREATE PROCEDURE staging.chkfk_kihon_tx()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_tx
        FROM staging.kihon_tx l
        LEFT JOIN staging.dom_kihon_sequences fseq ON l.from_seq = fseq.id_sequence
        LEFT JOIN staging.dom_kihon_sequences tseq ON l.to_seq = tseq.id_sequence
        WHERE fseq.id_sequence IS NULL OR tseq.id_sequence IS NULL
      )
    UPDATE staging.kihon_tx t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_tx = fk.id_tx;

END;

-- Checks FK for kata_sequence and moves invalid rows to reject.kata_sequence
CREATE PROCEDURE staging.chkfk_kata_sequence()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_sequence
        FROM staging.kata_sequence l
        LEFT JOIN staging.dom_kata_inventory ki ON l.kata_id = ki.id_kata
        LEFT JOIN staging.dom_stands s ON l.stand_id = s.id_stand
        WHERE ki.id_kata IS NULL OR s.id_stand IS NULL
      )
    UPDATE staging.kata_sequence t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_sequence = fk.id_sequence;

END;

-- Checks FK for kata_sequence_waza and moves invalid rows to reject.kata_sequence_waza
CREATE PROCEDURE staging.chkfk_kata_sequence_waza()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_kswaza
        FROM staging.kata_sequence_waza l
        LEFT JOIN staging.dom_kata_sequence ks ON l.sequence_id = ks.id_sequence
        LEFT JOIN staging.dom_technics te ON l.technic_id = te.id_technic
        LEFT JOIN staging.dom_strikingparts sp ON l.strikingpart_id = sp.id_part
        LEFT JOIN staging.dom_targets ta ON l.technic_target_id = ta.id_target
        WHERE ks.id_sequence IS NULL OR te.id_technic IS NULL
          OR (l.strikingpart_id IS NOT NULL AND sp.id_part IS NULL)
          OR (l.technic_target_id IS NOT NULL AND ta.id_target IS NULL)
      )
    UPDATE staging.kata_sequence_waza t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_kswaza = fk.id_kswaza;

END;

-- Checks FK for kata_tx and moves invalid rows to reject.kata_tx
CREATE PROCEDURE staging.chkfk_kata_tx()
LANGUAGE SQL
BEGIN ATOMIC;
    WITH 
      fk_error AS (
        SELECT id_tx
        FROM staging.kata_tx l
        LEFT JOIN staging.dom_kata_sequence fseq ON l.from_seq = fseq.id_sequence
        LEFT JOIN staging.dom_kata_sequence tseq ON l.to_seq = tseq.id_sequence
        LEFT JOIN staging.dom_stands s ON l.intermediate_stand = s.id_stand
        WHERE fseq.id_sequence IS NULL OR tseq.id_sequence IS NULL
          OR (l.intermediate_stand IS NOT NULL AND s.id_stand IS NULL)
      )
    UPDATE staging.kata_tx t
    SET staging_fk_error = true
    FROM fk_error fk
    WHERE t.id_tx = fk.id_tx;

END;

-- Upserts and moves rows from staging.targets to upsert/reject
CREATE PROCEDURE staging.feed_targets()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.targets t
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
    INSERT INTO ski.targets(
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

-- Upserts and moves rows from staging.strikingparts to upsert/reject
CREATE PROCEDURE staging.feed_strikingparts()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.strikingparts t
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
    INSERT INTO ski.strikingparts(
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

CREATE PROCEDURE staging.feed_technics()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.technics t
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
    INSERT INTO ski.technics(
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

CREATE PROCEDURE staging.feed_stands()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.stands t
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
    INSERT INTO ski.stands(
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

CREATE PROCEDURE staging.feed_grades()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.grades t
    SET id_grade = staging.id_grade,
        gtype = staging.gtype,
        grade = staging.grade,
        color = staging.color
    FROM staging.grades staging
    WHERE t.id_grade = staging.id_grade
    RETURNING t.id_grade
),
tbl_update AS (
    INSERT INTO ski.grades(
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

-- Upserts and moves rows from staging.kihon_inventory to upsert/reject
CREATE PROCEDURE staging.feed_kihon_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kihon_inventory inv
    SET id_inventory = staging.id_inventory,
        grade_id = staging.grade_id,
        number = staging.number,
        notes = staging.notes
    FROM staging.kihon_inventory staging
    WHERE inv.id_inventory = staging.id_inventory
    RETURNING inv.id_inventory
),
tbl_update AS (
    INSERT INTO ski.kihon_inventory(
        id_inventory, grade_id, number, notes
    )
    SELECT id_inventory, grade_id, number, notes
    FROM (
        SELECT tot.id_inventory, grade_id, number, notes
        FROM staging.kihon_inventory tot
        LEFT JOIN tbl_pk_update esc ON tot.id_inventory = esc.id_inventory
        WHERE esc.id_inventory IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.kihon_sequences to upsert/reject
CREATE PROCEDURE staging.feed_kihon_sequences()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kihon_sequences seq
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
    INSERT INTO ski.kihon_sequences(
        id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
    )
    SELECT id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
    FROM (
        SELECT tot.id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes, resource_url
        FROM staging.kihon_sequences tot
        LEFT JOIN tbl_pk_update esc ON tot.id_sequence = esc.id_sequence
        WHERE esc.id_sequence IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.kihon_tx to upsert/reject
CREATE PROCEDURE staging.feed_kihon_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kihon_tx tx
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
    INSERT INTO ski.kihon_tx(
        id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
    )
    SELECT id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
    FROM (
        SELECT tot.id_tx, from_seq, to_seq, movement, notes, tempo, resource_url
        FROM staging.kihon_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.Kata_inventory to upsert/reject
CREATE PROCEDURE staging.feed_Kata_inventory()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.Kata_inventory kata
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
    INSERT INTO ski.Kata_inventory(
        id_kata, kata, serie, starting_leg, notes, resource_url
    )
    SELECT id_kata, kata, serie, starting_leg, notes, resource_url
    FROM (
        SELECT tot.id_kata, kata, serie, starting_leg, notes, resource_url
        FROM staging.Kata_inventory tot
        LEFT JOIN tbl_pk_update esc ON tot.id_kata = esc.id_kata
        WHERE esc.id_kata IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.kata_sequence to upsert/reject
CREATE PROCEDURE staging.feed_kata_sequence()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kata_sequence seq
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
    INSERT INTO ski.kata_sequence(
        id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
    )
    SELECT id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
    FROM (
        SELECT tot.id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes, resource_url
        FROM staging.kata_sequence tot
        LEFT JOIN tbl_pk_update esc ON tot.id_sequence = esc.id_sequence
        WHERE esc.id_sequence IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.kata_sequence_waza to upsert/reject
CREATE PROCEDURE staging.feed_kata_sequence_waza()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kata_sequence_waza waza
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
    INSERT INTO ski.kata_sequence_waza(
        id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
    )
    SELECT id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
    FROM (
        SELECT tot.id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes
        FROM staging.kata_sequence_waza tot
        LEFT JOIN tbl_pk_update esc ON tot.id_kswaza = esc.id_kswaza
        WHERE esc.id_kswaza IS NULL
            AND tot.staging_fk_error IS NOT false
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

-- Upserts and moves rows from staging.kata_tx to upsert/reject
CREATE PROCEDURE staging.feed_kata_tx()
LANGUAGE SQL
BEGIN ATOMIC;
WITH
tbl_pk_update AS (
    UPDATE ski.kata_tx tx
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
    INSERT INTO ski.kata_tx(
        id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
    )
    SELECT id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
    FROM (
        SELECT tot.id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes, resource_url
        FROM staging.kata_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
            AND tot.staging_fk_error IS NOT false
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

DELETE FROM staging.kata_tx;
END;

-- Loads and processes all targets from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_targets()
LANGUAGE SQL AS $proc$
    CALL staging.fill_targets();
    -- No FK check for targets
    CALL staging.feed_targets();
$proc$;

-- Loads and processes all strikingparts from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_strikingparts()
LANGUAGE SQL AS $proc$

    CALL staging.fill_strikingparts();
    -- No FK check for strikingparts
    CALL staging.feed_strikingparts();

$proc$;

-- Loads and processes all technics from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_technics()
LANGUAGE SQL AS $proc$

    CALL staging.fill_technics();
    -- No FK check for technics
    CALL staging.feed_technics();

$proc$;

-- Loads and processes all stands from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_stands()
LANGUAGE SQL AS $proc$

    CALL staging.fill_stands();
    -- No FK check for stands
    CALL staging.feed_stands();

$proc$;

-- Loads and processes all grades from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_grades()
LANGUAGE SQL AS $proc$

    CALL staging.fill_grades();
    -- No FK check for grades
    CALL staging.feed_grades();

$proc$;

-- Loads and processes all kihon_inventory from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kihon_inventory()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kihon_inventory();
    CALL staging.chkfk_kihon_inventory();
    CALL staging.feed_kihon_inventory();

$proc$;

-- Loads and processes all kihon_sequences from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kihon_sequences()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kihon_sequences();
    CALL staging.chkfk_kihon_sequences();
    CALL staging.feed_kihon_sequences();

$proc$;

-- Loads and processes all kihon_tx from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kihon_tx()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kihon_tx();
    CALL staging.chkfk_kihon_tx();
    CALL staging.feed_kihon_tx();

$proc$;

-- Loads and processes all Kata_inventory from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_Kata_inventory()
LANGUAGE SQL AS $proc$

    CALL staging.fill_Kata_inventory();
    -- No FK check for Kata_inventory
    CALL staging.feed_Kata_inventory();

$proc$;

-- Loads and processes all kata_sequence from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kata_sequence()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kata_sequence();
    CALL staging.chkfk_kata_sequence();
    CALL staging.feed_kata_sequence();

$proc$;

-- Loads and processes all kata_sequence_waza from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kata_sequence_waza()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kata_sequence_waza();
    CALL staging.chkfk_kata_sequence_waza();
    CALL staging.feed_kata_sequence_waza();

$proc$;

-- Loads and processes all kata_tx from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.load_kata_tx()
LANGUAGE SQL AS $proc$

    CALL staging.fill_kata_tx();
    CALL staging.chkfk_kata_tx();
    CALL staging.feed_kata_tx();

$proc$;

-- Loads and processes all kihon-related tables from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.dump_kihon()
LANGUAGE SQL AS $proc$
    CALL staging.fill_kihon_inventory();
    CALL staging.chkfk_kihon_inventory();
    CALL staging.feed_kihon_inventory();

    CALL staging.fill_kihon_sequences();
    CALL staging.chkfk_kihon_sequences();
    CALL staging.feed_kihon_sequences();

    CALL staging.fill_kihon_tx();
    CALL staging.chkfk_kihon_tx();
    CALL staging.feed_kihon_tx();
$proc$;

-- Loads and processes all kata-related tables from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.dump_kata()
LANGUAGE SQL AS $proc$
    CALL staging.feed_kihon_inventory();

    CALL staging.fill_kihon_sequences();
    CALL staging.chkfk_kihon_sequences();
    CALL staging.feed_kihon_sequences();

    CALL staging.fill_kihon_tx();
    CALL staging.chkfk_kihon_tx();
    CALL staging.feed_kihon_tx();

$proc$;

-- Loads and processes all kata-related tables from staging to ski schema
CREATE OR REPLACE PROCEDURE staging.dump_kata()
LANGUAGE SQL AS $proc$

    CALL staging.fill_Kata_inventory();
    -- No FK check for Kata_inventory
    CALL staging.feed_Kata_inventory();

    CALL staging.fill_kata_sequence();
    CALL staging.chkfk_kata_sequence();
    CALL staging.feed_kata_sequence();

    CALL staging.fill_kata_sequence_waza();
    CALL staging.chkfk_kata_sequence_waza();
    CALL staging.feed_kata_sequence_waza();

    CALL staging.fill_kata_tx();
    CALL staging.chkfk_kata_tx();
    CALL staging.feed_kata_tx();

$proc$;




CREATE OR REPLACE FUNCTION staging.trigger_function()
   RETURNS TRIGGER
   LANGUAGE PLPGSQL VOLATILE
AS
$$
BEGIN
    WITH 
    res_seq AS (
        SELECT setval('ski.seq_id_technic', MAX(id_technic), true) FROM staging.dom_technics
    ),
    assign_id AS (
        UPDATE staging.technics
        SET id_technic = nextval('ski.seq_id_technic')
        WHERE id_technic IS NULL
        RETURNING id_technic
    )
    UPDATE staging.technics
    SET staging_autoid = true
    FROM assign_id
    WHERE technics.id_technic = assign_id.id_technic;

    UPDATE staging.technics
    SET staging_autoid = false
    WHERE staging_autoid IS NULL;

    WITH
    tbl_pk_update AS (
        UPDATE ski.technics t
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
        INSERT INTO ski.technics(
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
  
    INSERT INTO upsert.technics (
        id_technic, waza, name, description, notes, resource_url,
        staging_autoid, staging_pk_update, staging_update
    )
    SELECT id_technic, waza, name, description, notes, resource_url,
        staging_autoid, staging_pk_update, staging_update 
    FROM staging.technics
    WHERE staging_pk_update = true OR staging_update = true;

    DELETE FROM staging.technics
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.technics (
        id_technic, waza, name, description, notes, resource_url,
        staging_autoid, staging_pk_update, staging_update
    )
    SELECT id_technic, waza, name, description, notes, resource_url,
        staging_autoid, staging_pk_update, staging_update 
    FROM staging.technics;

    DELETE FROM staging.technics;

    RETURN NULL;
END;
$$;
