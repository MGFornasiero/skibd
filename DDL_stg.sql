
-- =============================================================
-- Staging/Upsert/Reject tables
-- This section defines tables for staging, upsert, and reject mechanisms.
-- =============================================================

-- ---------- Staging ----------
CREATE TABLE staging.targets(
  id_target SMALLINT UNIQUE,
  name VARCHAR(255) NOT NULL,
  original_name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_targets_name UNIQUE(name)
);

CREATE TABLE staging.strikingparts( 
  id_part SMALLINT UNIQUE,
  name VARCHAR(255) NOT NULL,
  translation VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_strikingparts_name UNIQUE(name)
);

CREATE TABLE staging.technics(
  id_technic SMALLINT UNIQUE,
  waza public.waza_type,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_technics_name UNIQUE(name)
);

CREATE TABLE staging.technics_decomposition(
  id_decomposition SMALLINT UNIQUE,
  technic_id SMALLINT NOT NULL,
  component_order SMALLINT NOT NULL,
  description TEXT,
  explatations TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_technics_decomposition UNIQUE (technic_id, component_order)
);

CREATE TABLE staging.stands(
  id_stand SMALLINT UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  illustration_url TEXT,
  notes TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_stands_name UNIQUE(name)
);

CREATE TABLE staging.grades(
  id_grade SMALLINT UNIQUE,
  gtype public.grade_type NOT NULL,
  grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
  color public.beltcolor,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_grades UNIQUE (gtype, grade)
);

CREATE TABLE staging.kihon_inventory(
  id_inventory SMALLINT,
  grade_id SMALLINT NOT NULL,
  number SMALLINT NOT NULL,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_kihon_inventory UNIQUE (grade_id, number)
);

CREATE TABLE staging.kihon_sequences(
  id_sequence SMALLINT UNIQUE,
  inventory_id SMALLINT NOT NULL,
  seq_num SMALLINT NOT NULL,
  stand_id SMALLINT NOT NULL,
  technic_id SMALLINT NOT NULL,
  -- hips public.hips, -- Temporarily removed
  gyaku bool DEFAULT false,
  target_hgt public.target_hgt,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_kihon_sequences UNIQUE (inventory_id, seq_num)
);

CREATE TABLE staging.kihon_tx(
  id_tx SMALLINT UNIQUE,
  from_sequence SMALLINT NOT NULL,
  to_sequence SMALLINT NOT NULL,
  movement public.movements,
  notes TEXT,
  tempo public.tempo,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_kihon_tx UNIQUE (from_sequence, to_sequence)
);

CREATE TABLE staging.kata_inventory(
  id_kata SMALLINT UNIQUE,
  kata VARCHAR(255) NOT NULL,
  serie public.kata_series,
  starting_leg public.sides NOT NULL,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_kata UNIQUE (kata)
);

CREATE TABLE staging.kata_sequence(
  id_sequence SMALLINT UNIQUE,
  kata_id SMALLINT NOT NULL,
  seq_num SMALLINT NOT NULL,
  stand_id SMALLINT NOT NULL,
  speed public.tempo,
  side public.sides,
  -- hips public.hips, -- Temporarily removed
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_kata_seq UNIQUE (kata_id, seq_num)
);

CREATE TABLE staging.kata_sequence_waza (
  id_kswaza SMALLINT UNIQUE,
  sequence_id SMALLINT,
  arto public.bodypart,
  technic_id SMALLINT NOT NULL,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL
);

CREATE TABLE staging.kata_tx (
  id_tx SMALLINT UNIQUE,
  from_sequence SMALLINT NOT NULL,
  to_sequence SMALLINT NOT NULL,
  tempo public.tempo,
  direction public.sides,
  intermediate_stand_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB, 
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL
);

CREATE TABLE staging.bunkai_inventory (
  id_bunkai SMALLINT,
  kata_id SMALLINT NOT NULL,
  version SMALLINT DEFAULT 1,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  notes TEXT,
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_bunkai_inventory UNIQUE (kata_id, version)
);

CREATE TABLE staging.bunkai_sequences (
  id_bunkaisequence SMALLINT UNIQUE,
  bunkai_id SMALLINT NOT NULL,
  kata_sequence_id SMALLINT NOT NULL,
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_staging_bunkai_sequence UNIQUE (bunkai_id, kata_sequence_id)
);

-- ---------- Upsert ----------
CREATE TABLE upsert.technics(
  id_technic SMALLINT,
  waza public.waza_type,
  name VARCHAR(255),
  description TEXT, 
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.technics_decomposition(
  id_decomposition SMALLINT,
  technic_id SMALLINT,
  component_order SMALLINT,
  description TEXT,
  explatations TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.targets(
  id_target SMALLINT,
  name VARCHAR(255),
  original_name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.strikingparts(
  id_part SMALLINT,
  name VARCHAR(255),
  translation VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.stands(
  id_stand SMALLINT,
  name VARCHAR(255),
  description TEXT,
  illustration_url TEXT,
  notes TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.grades(
  id_grade SMALLINT,
  gtype public.grade_type,
  grade SMALLINT,
  color public.beltcolor,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kihon_inventory(
  id_inventory SMALLINT,
  grade_id SMALLINT,
  number SMALLINT,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kihon_sequences(
  id_sequence SMALLINT,
  inventory_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  technic_id SMALLINT,
  -- hips public.hips, -- Temporarily removed
  gyaku bool,
  target_hgt public.target_hgt,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kihon_tx(
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  movement public.movements,
  notes TEXT,
  tempo public.tempo,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kata_inventory(
  id_kata SMALLINT,
  kata VARCHAR(255),
  serie public.kata_series,
  starting_leg public.sides,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kata_sequence(
  id_sequence SMALLINT,
  kata_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  speed public.tempo,
  side public.sides,
  -- hips public.hips, -- Temporarily removed
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kata_sequence_waza(
  id_kswaza SMALLINT,
  sequence_id SMALLINT,
  arto public.bodypart,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kata_tx(
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  tempo public.tempo,
  direction public.sides,
  intermediate_stand_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB, 
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.bunkai_inventory (
  id_bunkai SMALLINT,
  kata_id SMALLINT,
  version SMALLINT,
  name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.bunkai_sequences (
  id_bunkaisequence SMALLINT,
  bunkai_id SMALLINT,
  kata_sequence_id SMALLINT,
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

-- ---------- Reject ----------
CREATE TABLE reject.technics(
  id_technic SMALLINT,
  waza public.waza_type,
  name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.technics_decomposition(
  id_decomposition SMALLINT,
  technic_id SMALLINT,
  component_order SMALLINT,
  description TEXT,
  explatations TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.targets(
  id_target SMALLINT,
  name VARCHAR(255),
  original_name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.strikingparts(
  id_part SMALLINT,
  name VARCHAR(255),
  translation VARCHAR(255),
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.stands(
  id_stand SMALLINT,
  name VARCHAR(255),
  description TEXT,
  illustration_url TEXT,
  notes TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.grades(
  id_grade SMALLINT,
  gtype public.grade_type,
  grade SMALLINT,
  color public.beltcolor,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kihon_inventory(
  id_inventory SMALLINT,
  grade_id SMALLINT,
  number SMALLINT,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kihon_sequences(
  id_sequence SMALLINT,
  inventory_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  technic_id SMALLINT,
  -- hips public.hips, -- Temporarily removed
  gyaku bool,
  target_hgt public.target_hgt,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kihon_tx(
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  movement public.movements,
  notes TEXT,
  tempo public.tempo,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kata_inventory(
  id_kata SMALLINT,
  kata VARCHAR(255),
  serie public.kata_series,
  starting_leg public.sides,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kata_sequence(
  id_sequence SMALLINT,
  kata_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  speed public.tempo,
  side public.sides,
  -- hips public.hips, -- Temporarily removed
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
  notes TEXT, 
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kata_sequence_waza(
  id_kswaza SMALLINT,
  sequence_id SMALLINT,
  arto public.bodypart,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kata_tx(
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  tempo public.tempo,
  direction public.sides,
  intermediate_stand_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
  resources JSONB, 
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.bunkai_inventory (
  id_bunkai SMALLINT,
  kata_id SMALLINT,
  version SMALLINT,
  name VARCHAR(255),
  description TEXT,
  notes TEXT,
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.bunkai_sequences (
  id_bunkaisequence SMALLINT,
  bunkai_id SMALLINT,
  kata_sequence_id SMALLINT,
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);
-- =============================================================
-- Views (staging domain unions so keys are visible for ETL)
-- This section creates views for staging domain unions.
-- =============================================================
CREATE VIEW staging.dom_targets AS
  SELECT id_target FROM ski.targets
  UNION
  SELECT id_target FROM staging.targets;

CREATE VIEW staging.dom_strikingparts AS
  SELECT id_part FROM ski.strikingparts
  UNION
  SELECT id_part FROM staging.strikingparts;

CREATE VIEW staging.dom_technics AS
  SELECT id_technic FROM ski.technics
  UNION
  SELECT id_technic FROM staging.technics;

CREATE VIEW staging.dom_technics_decomposition AS
  SELECT id_decomposition FROM ski.technics_decomposition
  UNION
  SELECT id_decomposition FROM staging.technics_decomposition;

CREATE VIEW staging.dom_stands AS
  SELECT id_stand FROM ski.stands
  UNION
  SELECT id_stand FROM staging.stands;

CREATE VIEW staging.dom_grades AS
  SELECT id_grade FROM ski.grades
  UNION
  SELECT id_grade FROM staging.grades;

CREATE VIEW staging.dom_kihon_inventory AS
  SELECT id_inventory FROM ski.kihon_inventory
  UNION
  SELECT id_inventory FROM staging.kihon_inventory;

CREATE VIEW staging.dom_kihon_sequences AS
  SELECT id_sequence FROM ski.kihon_sequences
  UNION
  SELECT id_sequence FROM staging.kihon_sequences;

CREATE VIEW staging.dom_kihon_tx AS
  SELECT id_tx FROM ski.kihon_tx
  UNION
  SELECT id_tx FROM staging.kihon_tx;

CREATE VIEW staging.dom_kata_inventory AS
  SELECT id_kata FROM ski.kata_inventory
  UNION
  SELECT id_kata FROM staging.kata_inventory;

CREATE VIEW staging.dom_kata_sequence AS
  SELECT id_sequence FROM ski.kata_sequence
  UNION
  SELECT id_sequence FROM staging.kata_sequence;

CREATE VIEW staging.dom_kata_sequence_waza AS
  SELECT id_kswaza FROM ski.kata_sequence_waza
  UNION
  SELECT id_kswaza FROM staging.kata_sequence_waza;

CREATE VIEW staging.dom_kata_tx AS
  SELECT id_tx FROM ski.kata_tx
  UNION
  SELECT id_tx FROM staging.kata_tx;

CREATE VIEW staging.dom_bunkai_inventory AS
  SELECT id_bunkai FROM ski.bunkai_inventory
  UNION
  SELECT id_bunkai FROM staging.bunkai_inventory;

CREATE VIEW staging.dom_bunkai_sequences AS
  SELECT id_bunkaisequence FROM ski.bunkai_sequences
  UNION
  SELECT id_bunkaisequence FROM staging.bunkai_sequences;

--
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_technics()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS $Func$
    DECLARE
    seq_adj integer;
    tms_op timestamp;
    BEGIN
    SELECT INTO seq_adj setval('ski.seq_id_technic', MAX(id_technic), true) FROM staging.dom_technics;
    SELECT INTO tms_op CURRENT_TIMESTAMP;
    WITH 
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
    dupkey AS (
    SELECT l.id_technic ,
      l.waza ,
      l.name ,
      l.description ,
      l.notes ,
      l.resource_url
    FROM staging.technics l
    INNER JOIN ski.technics r
    ON l.id_technic = r.id_technic
    ),
    tbl_pk_update AS (
      UPDATE ski.technics t
      SET waza = dupkey.waza,
        name = dupkey.name,
        description = dupkey.description,
        notes = dupkey.notes,
        resource_url = dupkey.resource_url
      FROM dupkey
      WHERE t.id_technic = dupkey.id_technic
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
      ON CONFLICT (name) -- ON CONSTRAINT unique_technicname
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
      staging_autoid, insertion
    )
    SELECT id_technic, waza, name, description, notes, resource_url,
      staging_autoid,  tms_op
    FROM staging.technics
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.technics (
      id_technic, waza, name, description, notes, resource_url,
      staging_autoid, insertion
    )
    SELECT id_technic, waza, name, description, notes, resource_url,
      staging_autoid, tms_op
    FROM staging.technics
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.technics;

    RETURN NULL;
    END;
  $Func$
;

-- Targets
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_targets()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_id_target', MAX(id_target), true) FROM staging.dom_targets;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.targets SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_target, l.name, l.original_name, l.description, l.notes, l.resource_url
    FROM staging.targets l
    INNER JOIN ski.targets r ON l.id_target = r.id_target
    ),
    tbl_pk_update AS (
      UPDATE ski.targets t
      SET name = dupkey.name,
        original_name = dupkey.original_name,
        description = dupkey.description,
        notes = dupkey.notes,
        resource_url = dupkey.resource_url
      FROM dupkey
      WHERE t.id_target = dupkey.id_target
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

    INSERT INTO upsert.targets (
      id_target, name, original_name, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_target, name, original_name, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.targets
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.targets (
      id_target, name, original_name, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_target, name, original_name, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.targets
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.targets;

    RETURN NULL;
  END;
  $Func$
;

-- Strikingparts
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_strikingparts()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_id_part', MAX(id_part), true) FROM staging.dom_strikingparts;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.strikingparts SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_part, l.name, l.translation, l.description, l.notes, l.resource_url
    FROM staging.strikingparts l
    INNER JOIN ski.strikingparts r ON l.id_part = r.id_part
    ),
    tbl_pk_update AS (
      UPDATE ski.strikingparts t
      SET name = dupkey.name,
        translation = dupkey.translation,
        description = dupkey.description,
        notes = dupkey.notes,
        resource_url = dupkey.resource_url
      FROM dupkey
      WHERE t.id_part = dupkey.id_part
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

    INSERT INTO upsert.strikingparts (
      id_part, name, translation, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_part, name, translation, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.strikingparts
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.strikingparts (
      id_part, name, translation, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_part, name, translation, description, notes, resource_url,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.strikingparts
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.strikingparts;

    RETURN NULL;
  END;
  $Func$
;

-- Stands
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_stands()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_id_stand', MAX(id_stand), true) FROM staging.dom_stands;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.stands SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_stand, l.name, l.description, l.illustration_url, l.notes
    FROM staging.stands l
    INNER JOIN ski.stands r ON l.id_stand = r.id_stand
    ),
    tbl_pk_update AS (
      UPDATE ski.stands t
      SET name = dupkey.name,
        description = dupkey.description,
        illustration_url = dupkey.illustration_url,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_stand = dupkey.id_stand
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

    INSERT INTO upsert.stands (
      id_stand, name, description, illustration_url, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_stand, name, description, illustration_url, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.stands
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.stands (
      id_stand, name, description, illustration_url, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_stand, name, description, illustration_url, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.stands
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.stands;

    RETURN NULL;
  END;
  $Func$
;

-- Grades
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_grades()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_id_grade', MAX(id_grade), true) FROM staging.dom_grades;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.grades SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_grade, l.gtype, l.grade, l.color
    FROM staging.grades l
    INNER JOIN ski.grades r ON l.id_grade = r.id_grade
    ),
    tbl_pk_update AS (
      UPDATE ski.grades t
      SET gtype = dupkey.gtype,
        grade = dupkey.grade,
        color = dupkey.color
      FROM dupkey
      WHERE t.id_grade = dupkey.id_grade
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

    INSERT INTO upsert.grades (
      id_grade, gtype, grade, color,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_grade, gtype, grade, color,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.grades
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.grades (
      id_grade, gtype, grade, color,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_grade, gtype, grade, color,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.grades
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.grades;

    RETURN NULL;
  END;
  $Func$
;

-- Kihon Inventory
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_inventory()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_inventory', MAX(id_inventory), true) FROM staging.dom_kihon_inventory;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kihon_inventory SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_inventory, l.grade_id, l.number, l.notes
    FROM staging.kihon_inventory l
    INNER JOIN ski.kihon_inventory r ON l.id_inventory = r.id_inventory
    ),
    tbl_pk_update AS (
      UPDATE ski.kihon_inventory t
      SET grade_id = dupkey.grade_id,
        number = dupkey.number,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_inventory = dupkey.id_inventory
      RETURNING t.id_inventory
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

    INSERT INTO upsert.kihon_inventory (
      id_inventory, grade_id, number, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_inventory, grade_id, number, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_inventory
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kihon_inventory (
      id_inventory, grade_id, number, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_inventory, grade_id, number, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_inventory
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kihon_inventory;

    RETURN NULL;
  END;
  $Func$
;

-- Kihon Sequences
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_sequences()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_sequence', MAX(id_sequence), true) FROM staging.dom_kihon_sequences;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kihon_sequences SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_sequence, l.inventory_id, l.seq_num, l.stand_id, l.technic_id, l.gyaku, l.target_hgt, l.notes
    FROM staging.kihon_sequences l
    INNER JOIN ski.kihon_sequences r ON l.id_sequence = r.id_sequence
    ),
    tbl_pk_update AS (
      UPDATE ski.kihon_sequences t
      SET inventory_id = dupkey.inventory_id,
        seq_num = dupkey.seq_num,
        stand_id = dupkey.stand_id,
        technic_id = dupkey.technic_id,
        gyaku = dupkey.gyaku,
        target_hgt = dupkey.target_hgt,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_sequence = dupkey.id_sequence
      RETURNING t.id_sequence
    ),
    tbl_update AS (
      INSERT INTO ski.kihon_sequences(
        id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes
      )
      SELECT id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes
      FROM (
        SELECT tot.id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes
        FROM staging.kihon_sequences tot
        LEFT JOIN tbl_pk_update esc ON tot.id_sequence = esc.id_sequence
        WHERE esc.id_sequence IS NULL
      )
      ON CONFLICT (inventory_id, seq_num)
      DO UPDATE SET
        id_sequence = EXCLUDED.id_sequence,
        inventory_id = EXCLUDED.inventory_id,
        seq_num = EXCLUDED.seq_num,
        stand_id = EXCLUDED.stand_id,
        technic_id = EXCLUDED.technic_id,
        gyaku = EXCLUDED.gyaku,
        target_hgt = EXCLUDED.target_hgt,
        notes = EXCLUDED.notes
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

    INSERT INTO upsert.kihon_sequences (
      id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_sequences
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kihon_sequences (
      id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, inventory_id, seq_num, stand_id, technic_id, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_sequences
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kihon_sequences;

    RETURN NULL;
  END;
  $Func$
;

-- Kihon TX
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_tx()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_tx', MAX(id_tx), true) FROM staging.dom_kihon_tx;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kihon_tx SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_tx, l.from_sequence, l.to_sequence, l.movement, l.notes, l.tempo
    FROM staging.kihon_tx l
    INNER JOIN ski.kihon_tx r ON l.id_tx = r.id_tx
    ),
    tbl_pk_update AS (
      UPDATE ski.kihon_tx t
      SET from_sequence = dupkey.from_sequence,
        to_sequence = dupkey.to_sequence,
        movement = dupkey.movement,
        notes = dupkey.notes,
        tempo = dupkey.tempo
      FROM dupkey
      WHERE t.id_tx = dupkey.id_tx
      RETURNING t.id_tx
    ),
    tbl_update AS (
      INSERT INTO ski.kihon_tx(
        id_tx, from_sequence, to_sequence, movement, notes, tempo
      )
      SELECT id_tx, from_sequence, to_sequence, movement, notes, tempo
      FROM (
        SELECT tot.id_tx, from_sequence, to_sequence, movement, notes, tempo
        FROM staging.kihon_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
      )
      ON CONFLICT (from_sequence, to_sequence)
      DO UPDATE SET
        id_tx = EXCLUDED.id_tx,
        from_sequence = EXCLUDED.from_sequence,
        to_sequence = EXCLUDED.to_sequence,
        movement = EXCLUDED.movement,
        notes = EXCLUDED.notes,
        tempo = EXCLUDED.tempo
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

    INSERT INTO upsert.kihon_tx (
      id_tx, from_sequence, to_sequence, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_sequence, to_sequence, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_tx
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kihon_tx (
      id_tx, from_sequence, to_sequence, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_sequence, to_sequence, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_tx
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kihon_tx;

    RETURN NULL;
  END;
  $Func$
;

-- Kata Inventory
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_inventory()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kata_id_kata', MAX(id_kata), true) FROM staging.dom_kata_inventory;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kata_inventory SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_kata, l.kata, l.serie, l.starting_leg, l.notes
    FROM staging.kata_inventory l
    INNER JOIN ski.kata_inventory r ON l.id_kata = r.id_kata
    ),
    tbl_pk_update AS (
      UPDATE ski.kata_inventory t
      SET kata = dupkey.kata,
        serie = dupkey.serie,
        starting_leg = dupkey.starting_leg,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_kata = dupkey.id_kata
      RETURNING t.id_kata
    ),
    tbl_update AS (
      INSERT INTO ski.kata_inventory(
        id_kata, kata, serie, starting_leg, notes
      )
      SELECT id_kata, kata, serie, starting_leg, notes
      FROM (
        SELECT tot.id_kata, kata, serie, starting_leg, notes
        FROM staging.kata_inventory tot
        LEFT JOIN tbl_pk_update esc ON tot.id_kata = esc.id_kata
        WHERE esc.id_kata IS NULL
      )
      ON CONFLICT (kata)
      DO UPDATE SET
        id_kata = EXCLUDED.id_kata,
        kata = EXCLUDED.kata,
        serie = EXCLUDED.serie,
        starting_leg = EXCLUDED.starting_leg,
        notes = EXCLUDED.notes
      RETURNING id_kata
    ),
    details AS (
      SELECT base.id_kata,
        pk.id_kata IS NOT NULL AS staging_pk_update,
        upd.id_kata IS NOT NULL AS staging_update
      FROM staging.kata_inventory AS base
      LEFT JOIN tbl_pk_update AS pk ON base.id_kata = pk.id_kata
      LEFT JOIN tbl_update AS upd ON base.id_kata = upd.id_kata
    )
    UPDATE staging.kata_inventory t
    SET staging_pk_update = d.staging_pk_update,
      staging_update = d.staging_update
    FROM details d
    WHERE t.id_kata = d.id_kata;

    INSERT INTO upsert.kata_inventory (
      id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_inventory
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kata_inventory (
      id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_inventory
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kata_inventory;

    RETURN NULL;
  END;
  $Func$
;

-- Kata Sequences
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_sequences()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kata_id_sequence', MAX(id_sequence), true) FROM staging.dom_kata_sequence;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kata_sequence SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_sequence, l.kata_id, l.seq_num, l.stand_id, l.speed, l.side, l.embusen, l.facing, l.kiai, l.notes
    FROM staging.kata_sequence l
    INNER JOIN ski.kata_sequence r ON l.id_sequence = r.id_sequence
    ),
    tbl_pk_update AS (
      UPDATE ski.kata_sequence t
      SET kata_id = dupkey.kata_id,
        seq_num = dupkey.seq_num,
        stand_id = dupkey.stand_id,
        speed = dupkey.speed,
        side = dupkey.side,
        embusen = dupkey.embusen,
        facing = dupkey.facing,
        kiai = dupkey.kiai,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_sequence = dupkey.id_sequence
      RETURNING t.id_sequence
    ),
    tbl_update AS (
      INSERT INTO ski.kata_sequence(
        id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes
      )
      SELECT id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes
      FROM (
        SELECT tot.id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes
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
        notes = EXCLUDED.notes
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

    INSERT INTO upsert.kata_sequence (
      id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_sequence
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kata_sequence (
      id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, kata_id, seq_num, stand_id, speed, side, embusen, facing, kiai, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_sequence
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kata_sequence;

    RETURN NULL;
  END;
  $Func$
;

-- Kata Sequence Waza
-- pq: WITH query "tbl_update" does not have a RETURNING clause 
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_sequence_waza()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kata_id_kswaza', MAX(id_kswaza), true) FROM staging.dom_kata_sequence_waza;
  SELECT INTO tms_op CURRENT_TIMESTAMP;

  WITH 
    assign_id AS (
      UPDATE staging.kata_sequence_waza
      SET id_kswaza = nextval('ski.seq_kata_id_kswaza')
      WHERE id_kswaza IS NULL
      RETURNING id_kswaza
    )
  UPDATE staging.kata_sequence_waza
    SET staging_autoid = true
    FROM assign_id
    WHERE kata_sequence_waza.id_kswaza = assign_id.id_kswaza;

  UPDATE staging.kata_sequence_waza SET staging_autoid = false WHERE staging_autoid IS NULL;

    WITH
    dupkey AS (
    SELECT l.id_kswaza, l.sequence_id, l.arto, l.technic_id, l.strikingpart_id, l.technic_target_id, l.notes
    FROM staging.kata_sequence_waza l
    INNER JOIN ski.kata_sequence_waza r ON l.id_kswaza = r.id_kswaza
    ),
    tbl_pk_update AS (
      UPDATE ski.kata_sequence_waza t
      SET sequence_id = dupkey.sequence_id,
        arto = dupkey.arto,
        technic_id = dupkey.technic_id,
        strikingpart_id = dupkey.strikingpart_id,
        technic_target_id = dupkey.technic_target_id,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_kswaza = dupkey.id_kswaza
      RETURNING t.id_kswaza
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
      )
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

    INSERT INTO upsert.kata_sequence_waza (
      id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_sequence_waza
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kata_sequence_waza (
      id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kswaza, sequence_id, arto, technic_id, strikingpart_id, technic_target_id, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_sequence_waza
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kata_sequence_waza;

    RETURN NULL;
  END;
  $Func$
;

-- Kata TX
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_tx()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $Func$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kata_id_tx', MAX(id_tx), true) FROM staging.dom_kata_tx;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
  WITH 
    assign_id AS (
      UPDATE staging.kata_tx
      SET id_tx = nextval('ski.seq_kata_id_tx')
      WHERE id_tx IS NULL
      RETURNING id_tx
    )
    UPDATE staging.kata_tx
    SET staging_autoid = true
    FROM assign_id
    WHERE kata_tx.id_tx = assign_id.id_tx;

    UPDATE staging.kata_tx SET staging_autoid = false WHERE staging_autoid IS NULL;

    WITH
    dupkey AS (
    SELECT l.id_tx, l.from_sequence, l.to_sequence, l.tempo, l.direction, l.intermediate_stand_id, l.notes
    FROM staging.kata_tx l
    INNER JOIN ski.kata_tx r ON l.id_tx = r.id_tx
    ),
    tbl_pk_update AS (
      UPDATE ski.kata_tx t
      SET from_sequence = dupkey.from_sequence,
        to_sequence = dupkey.to_sequence,
        tempo = dupkey.tempo,
        direction = dupkey.direction,
        intermediate_stand_id= dupkey.intermediate_stand_id,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_tx = dupkey.id_tx
      RETURNING t.id_tx
    ),
    tbl_update AS (
      INSERT INTO ski.kata_tx(
        id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes
      )
      SELECT id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes
      FROM (
        SELECT tot.id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes
        FROM staging.kata_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
      )
      ON CONFLICT ON CONSTRAINT unique_kata_tx
      DO UPDATE SET
        id_tx = EXCLUDED.id_tx,
        from_sequence = EXCLUDED.from_sequence,
        to_sequence = EXCLUDED.to_sequence,
        tempo = EXCLUDED.tempo,
        direction = EXCLUDED.direction,
        intermediate_stand_id= EXCLUDED.intermediate_stand_id,
        notes = EXCLUDED.notes
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

    INSERT INTO upsert.kata_tx (
      id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_tx
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kata_tx (
      id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_sequence, to_sequence, tempo, direction, intermediate_stand_id, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_tx
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kata_tx;

    RETURN NULL;
  END;
  $Func$
;

--DROP TRIGGER IF EXISTS trigger_technics ON staging.technics;

CREATE TRIGGER trigger_technics
  AFTER INSERT
  ON staging.technics
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_technics()
;

CREATE TRIGGER trigger_targets
  AFTER INSERT
  ON staging.targets
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_targets()
;

CREATE TRIGGER trigger_strikingparts
  AFTER INSERT
  ON staging.strikingparts
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_strikingparts()
;

CREATE TRIGGER trigger_stands
  AFTER INSERT
  ON staging.stands
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_stands()
;

CREATE TRIGGER trigger_grades
  AFTER INSERT
  ON staging.grades
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_grades()
;

CREATE TRIGGER trigger_kihon_inventory
  AFTER INSERT
  ON staging.kihon_inventory
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kihon_inventory()
;

CREATE TRIGGER trigger_kihon_sequences
  AFTER INSERT
  ON staging.kihon_sequences
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kihon_sequences()
;

CREATE TRIGGER trigger_kihon_tx
  AFTER INSERT
  ON staging.kihon_tx
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kihon_tx()
;

CREATE TRIGGER trigger_kata_inventory
  AFTER INSERT
  ON staging.kata_inventory
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kata_inventory()
;

CREATE TRIGGER trigger_kata_sequence
  AFTER INSERT
  ON staging.kata_sequence
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kata_sequences()
;

CREATE TRIGGER trigger_kata_sequence_waza
  AFTER INSERT
  ON staging.kata_sequence_waza
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kata_sequence_waza()
;

CREATE TRIGGER trigger_kata_tx
  AFTER INSERT
  ON staging.kata_tx
  FOR EACH STATEMENT
  EXECUTE FUNCTION staging.trigfunc_ins_kata_tx()
;

-- Script di pulizia meccanismo di staging, cancella contenuto di staging e il contenuto di upsert e reject inserito da più di n giorni
CREATE OR REPLACE PROCEDURE staging.clean(_ts integer DEFAULT 7)
  LANGUAGE PLPGSQL AS 
  $proc$
    DELETE FROM upsert.technics WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.targets WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.strikingparts WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.stands WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.grades WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kihon_inventory WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kihon_sequences WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kihon_tx WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kata_inventory WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kata_sequence WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kata_sequence_waza WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM upsert.kata_tx WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.technics WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.targets WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.strikingparts WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.stands WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.grades WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kihon_inventory WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kihon_sequences WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kihon_tx WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kata_inventory WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kata_sequence WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kata_sequence_waza WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM reject.kata_tx WHERE DATE_PART('day', (CURRENT_TIMESTAMP- insertion)) >= _ts ;
    DELETE FROM staging.technics ;
    DELETE FROM staging.targets ;
    DELETE FROM staging.strikingparts ;
    DELETE FROM staging.stands ;
    DELETE FROM staging.grades ;
    DELETE FROM staging.kihon_inventory ;
    DELETE FROM staging.kihon_sequences ;
    DELETE FROM staging.kihon_tx ;
    DELETE FROM staging.kata_inventory ;
    DELETE FROM staging.kata_sequence ;
    DELETE FROM staging.kata_sequence_waza ;
    DELETE FROM staging.kata_tx ;
  $proc$
;

CREATE TABLE bkp.targets(
    bkp TIMESTAMP ,
    id_target SMALLINT,
    name VARCHAR(255) ,
    original_name VARCHAR(255),
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
; 

CREATE TABLE bkp.strikingparts( 
    bkp TIMESTAMP ,
    id_part SMALLINT ,
    name VARCHAR(255),
    translation VARCHAR(255),
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
; 

CREATE TABLE bkp.technics_decomposition(
    bkp TIMESTAMP ,
    id_decomposition SMALLINT,
    technic_id SMALLINT,
    component_order SMALLINT,
    description TEXT,
    explatations TEXT, 
    notes TEXT,
    resource_url TEXT
)
;


CREATE TABLE bkp.technics(
    bkp TIMESTAMP ,
    id_technic SMALLINT,
    waza waza_type,
    name VARCHAR(255) ,
    -- aka VARCHAR(255) ,
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
; 

CREATE TABLE bkp.stands(
    bkp TIMESTAMP ,
    id_stand SMALLINT ,
    name VARCHAR(255) ,
    description TEXT,
    illustration_url TEXT,
    notes TEXT
)
; 

CREATE TABLE bkp.grades(
    bkp TIMESTAMP ,
    id_grade SMALLINT ,
    gtype grade_type ,
    grade SMALLINT ,
    color beltcolor
)
; 

CREATE TABLE bkp.kihon_inventory(
    bkp TIMESTAMP ,
    id_inventory SMALLINT ,
    grade_id SMALLINT ,
    number SMALLINT ,
    notes TEXT
)
; 

CREATE TABLE bkp.kihon_sequences(
    bkp TIMESTAMP ,
    id_sequence SMALLINT ,
    inventory_id SMALLINT ,
    seq_num SMALLINT , -- Posizione ordinale nella sequenza
    stand_id SMALLINT ,
    technic_id SMALLINT ,
    gyaku bool,
    target_hgt target_hgt ,
    notes TEXT ,
    resource_url TEXT
)
; 

CREATE TABLE bkp.kihon_tx(
    bkp TIMESTAMP ,
    id_tx SMALLINT,
    from_sequence SMALLINT, 
    to_sequence SMALLINT,
    movement movements ,
    notes TEXT,
    tempo tempo ,
    resource_url TEXT
)
; 

CREATE TABLE bkp.kata_inventory(
    bkp TIMESTAMP ,
    id_kata SMALLINT,
    kata VARCHAR(255) ,
    serie kata_series,
    starting_leg sides ,
    notes TEXT,
    resource_url TEXT
)
; 

CREATE TABLE bkp.kata_sequence(
    bkp TIMESTAMP ,
    id_sequence SMALLINT ,
    kata_id SMALLINT ,
    seq_num SMALLINT ,
    stand_id SMALLINT ,
    speed tempo ,
    side sides, -- lato della guardia
    embusen embusen_points ,
    facing absolute_directions, -- direzioni cardinali rispetto all' inizio
    kiai bool,
    notes TEXT,
    resource_url TEXT
)
; 

CREATE TABLE bkp.kata_sequence_waza (
    bkp TIMESTAMP ,
    id_kswaza SMALLINT ,
    sequence_id SMALLINT,
    arto public.bodypart,
    technic_id SMALLINT ,
    strikingpart_id SMALLINT ,
    technic_target_id SMALLINT ,
    notes TEXT
)
;

CREATE TABLE bkp.kata_tx (
    bkp TIMESTAMP ,
    id_tx SMALLINT ,
    from_sequence SMALLINT ,
    to_sequence SMALLINT ,
    tempo tempo ,
    direction sides ,
    intermediate_stand_id SMALLINT ,
    notes TEXT,
    resource_url TEXT 
)
;

-- =============================================================
-- Backup Procedure
-- This section defines a procedure for backing up data from the `ski` schema.
-- =============================================================
CREATE OR REPLACE PROCEDURE ski.bkp()
    LANGUAGE PLPGSQL
    AS $proc$
    DECLARE
      tms_op TIMESTAMP;
    BEGIN
        SELECT INTO tms_op date_trunc('minute', CURRENT_TIMESTAMP);
    INSERT INTO bkp.targets (
        bkp  ,
        id_target ,
        name  ,
        original_name ,
        description ,
        notes ,
        resource_url 
    ) SELECT tms_op ,
        id_target ,
        name  ,
        original_name ,
        description ,
        notes ,
        resource_url 
    FROM ski.targets
    ; 

    INSERT INTO bkp.strikingparts ( 
        bkp  ,
        id_part  ,
        name ,
        translation ,
        description ,
        notes ,
        resource_url 
    ) SELECT tms_op ,
        id_part  ,
        name ,
        translation ,
        description ,
        notes ,
        resource_url 
    FROM ski.strikingparts
    ; 

    INSERT INTO bkp.technics (
        bkp  ,
        id_technic ,
        waza ,
        name  ,
        -- aka  ,
        description ,
        notes ,
        resource_url 
    ) SELECT tms_op ,
        id_technic ,
        waza ,
        name  ,
        description ,
        notes ,
        resource_url 
    FROM ski.technics
    ; 
    INSERT INTO bkp.stands (
        bkp,
        id_decomposition,
        technic_id,
        component_order,
        description,
        explatations, 
        notes,
        resource_url 
    ) SELECT tms_op ,
        id_decomposition,
        technic_id,
        component_order,
        description,
        explatations, 
        notes,
        resource_url
    FROM ski.technics_decomposition 
    ;
    INSERT INTO bkp.stands (
        bkp  ,
        id_stand  ,
        name  ,
        description ,
        illustration_url ,
        notes 
    ) SELECT tms_op ,
        id_stand  ,
        name  ,
        description ,
        illustration_url ,
        notes
    FROM ski.stands
    ; 

    INSERT INTO bkp.grades (
        bkp  ,
        id_grade  ,
        gtype ,
        grade  ,
        color
    ) SELECT tms_op ,
        id_grade  ,
        gtype ,
        grade  ,
        color
    FROM ski.grades
    ;

    INSERT INTO bkp.kihon_inventory (
        bkp  ,
        id_inventory  ,
        grade_id  ,
        number  ,
        notes 
    ) SELECT tms_op ,
        id_inventory  ,
        grade_id  ,
        number  ,
        notes 
    FROM ski.kihon_inventory
    ; 

    INSERT INTO bkp.kihon_sequences (
        bkp  ,
        id_sequence  ,
        inventory_id  ,
        seq_num  ,
        stand_id  ,
        technic_id  ,
        -- hips, -- Temporarily removed
        gyaku ,
        target_hgt ,
        notes  ,
        resource_url 
    ) SELECT tms_op ,
        id_sequence  ,
        inventory_id  ,
        seq_num  ,
        stand_id  ,
        technic_id  ,
        -- hips, -- Temporarily removed
        gyaku ,
        target_hgt ,
        notes  ,
        resource_url 
    FROM ski.kihon_sequences
    ; --Sequenza delle tecniche che compongono i kihon

    INSERT INTO bkp.kihon_tx (
        bkp  ,
        id_tx ,
        from_sequence , 
        to_sequence ,
        movement ,
        notes ,
        tempo ,
        resource_url 
    ) SELECT tms_op ,
        id_tx ,
        from_sequence , 
        to_sequence ,
        movement ,
        notes ,
        tempo ,
        resource_url 
    FROM ski.kihon_tx
    ; --Passaggio da una tecnica all' altra 

    INSERT INTO bkp.kata_inventory (
        bkp  ,
        id_kata ,
        kata  ,
        serie ,
        starting_leg ,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url 
    ) SELECT tms_op ,
        id_kata ,
        kata  ,
        serie ,
        starting_leg ,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url 
    FROM ski.kata_inventory
    ; -- Inventario in forma normale dei kata

    INSERT INTO bkp.kata_sequence (
        bkp  ,
        id_sequence  ,
        kata_id  ,
        seq_num  ,
        stand_id  ,
        speed ,
        side ,
        -- hips, -- Temporarily removed
        embusen ,
        facing , 
        kiai ,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url 
    ) SELECT tms_op ,
        id_sequence  ,
        kata_id  ,
        seq_num  ,
        stand_id  ,
        speed ,
        side ,
        -- hips, -- Temporarily removed
        embusen ,
        facing , 
        kiai,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url 
    FROM ski.kata_sequence
    ; 

    INSERT INTO bkp.kata_sequence_waza (
        bkp  ,
        id_kswaza  ,
        sequence_id  ,
        arto ,
        technic_id  ,
        strikingpart_id  ,
        technic_target_id  ,
        notes ,
        -- remarks, -- Temporarily removed
        resources 
    ) SELECT tms_op ,
        id_kswaza  ,
        sequence_id  ,
        arto ,
        technic_id  ,
        strikingpart_id  ,
        technic_target_id  ,
        notes ,
        -- remarks, -- Temporarily removed
        resources 
    FROM ski.kata_sequence_waza
    ;

    INSERT INTO bkp.kata_tx (
        bkp  ,
        id_tx  ,
        from_sequence  ,
        to_sequence  ,
        tempo ,
        direction ,
        intermediate_stand_id ,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url  
    ) SELECT tms_op ,
        id_tx  ,
        from_sequence  ,
        to_sequence  ,
        tempo ,
        direction ,
        intermediate_stand_id  ,
        notes ,
        -- remarks, -- Temporarily removed
        resources, 
        resource_url  
    FROM ski.kata_tx
    ;

    INSERT INTO bkp.bunkai_inventory (
        bkp,
        id_bunkai,
        kata_id,
        version,
        name,
        description,
        notes,
        resources,
        resource_url
    ) SELECT tms_op,
        id_bunkai,
        kata_id,
        version,
        name,
        description,
        notes,
        resources,
        resource_url
    FROM ski.bunkai_inventory;

    INSERT INTO bkp.bunkai_sequences (
        bkp, id_bunkaisequence, bunkai_id, kata_sequence_id,
        description, notes, remarks, resources, resource_url
    ) SELECT tms_op,
        id_bunkaisequence, bunkai_id, kata_sequence_id,
        description, notes, remarks, resources, resource_url
    FROM ski.bunkai_sequences;

    END;
$proc$;