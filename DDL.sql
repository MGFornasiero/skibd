-- =============================================================
-- Cleanup existing objects (if any)
-- This section removes existing roles, schemas, types, and functions
-- to ensure a clean slate before creating new objects.
-- =============================================================

DROP SCHEMA IF EXISTS ski CASCADE;
DROP SCHEMA IF EXISTS bkp CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
DROP SCHEMA IF EXISTS upsert CASCADE;
DROP SCHEMA IF EXISTS reject CASCADE;

DROP TYPE IF EXISTS arti CASCADE;
DROP TYPE IF EXISTS beltcolor CASCADE;
DROP TYPE IF EXISTS absolute_directions CASCADE;
DROP TYPE IF EXISTS embusen_points CASCADE;
DROP TYPE IF EXISTS tempo CASCADE;
DROP TYPE IF EXISTS waza_type CASCADE;
DROP TYPE IF EXISTS target_hgt CASCADE;
DROP TYPE IF EXISTS kata_series CASCADE;
DROP TYPE IF EXISTS movements CASCADE;
DROP TYPE IF EXISTS sides CASCADE;
DROP TYPE IF EXISTS grade_type CASCADE;
DROP TYPE IF EXISTS detailednotes CASCADE;
DROP TYPE IF EXISTS public.hips CASCADE;
DROP TYPE IF EXISTS public.limbs CASCADE;
DROP TYPE IF EXISTS public.bodypart CASCADE;


DO $Clean$
DECLARE
    r record;
BEGIN
    -- Loop through all functions in the 'public' schema
    FOR r IN
        SELECT 'DROP FUNCTION IF EXISTS ' || ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ') CASCADE;' as drop_cmd
        FROM pg_proc p
        JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE ns.nspname = 'public'
          AND p.prokind = 'f' -- 'f' for a normal function
    LOOP
        -- Execute the generated DROP command
        EXECUTE r.drop_cmd;
    END LOOP;
END $Clean$;

-- =============================================================
-- Create Schemas
-- This section creates the necessary schemas for the database.
-- =============================================================

CREATE SCHEMA ski;
CREATE SCHEMA bkp;
CREATE SCHEMA staging;
CREATE SCHEMA upsert;
CREATE SCHEMA reject;

-- =============================================================
-- Types (moved to public)
-- This section defines custom types used in the database.
-- =============================================================

-- Karate grading (kyu/dan)
CREATE TYPE public.grade_type AS ENUM ('kyu', 'dan');

-- Left/right/frontal sides
CREATE TYPE public.sides AS ENUM ('sx', 'frontal', 'dx');

-- Movements between steps
CREATE TYPE public.movements AS ENUM ('Fwd', 'Still', 'Bkw');

-- Kata series
CREATE TYPE public.kata_series AS ENUM ('Heian', 'Tekki', 'Sentei');

-- Target heights
CREATE TYPE public.target_hgt AS ENUM ('Jodan', 'Chudan', 'Gedan');

-- Technique type
CREATE TYPE public.waza_type AS ENUM ('Uke', 'Uchi', 'Geri', 'NA', '_');

-- Tempo
CREATE TYPE public.tempo AS ENUM ('Legato', 'Fast', 'Normal', 'Slow', 'Breath');

-- Embusen point (cartesian plane)
CREATE TYPE public.embusen_points AS (
  x SMALLINT,
  y SMALLINT
);

-- da rimuovere
CREATE TYPE public.arti AS ENUM (
  'Mano DX','Braccio DX', 'Braccio SX', 'Braccia',
  'Gamba DX',   'Gamba SX',   'Gambe',
  'NA'
);

CREATE TYPE public.limbs AS ENUM (
  'Mano','Braccio','Piede','Gamba','Ginochio','NA'
);

-- Tipo per sostituire arti in modo più dettagliato
CREATE TYPE public.bodypart AS (
  limb public.limbs,
  side public.sides  
);

CREATE TYPE public.hips AS ENUM ('Hanmi', 'Shomen');

-- Belt colors
CREATE TYPE public.beltcolor AS ENUM ('bianco','giallo','arancio','verde','blu','marrone','nero');

-- Absolute directions
CREATE TYPE public.absolute_directions AS ENUM ('N','NE','E','SE','S','SO','O','NO');

-- Detailed notes 
CREATE TYPE public.detailednotes AS (
  arto public.bodypart ,
  description TEXT ,
  explatation TEXT ,
  note TEXT
);
 

-- =============================================================
-- Sequences (kept in `ski`)
-- This section defines sequences for generating unique IDs.
-- =============================================================
CREATE SEQUENCE ski.seq_id_arti  AS SMALLINT;
CREATE SEQUENCE ski.seq_id_target  AS SMALLINT;
CREATE SEQUENCE ski.seq_id_part    AS SMALLINT;
CREATE SEQUENCE ski.seq_id_technic AS SMALLINT;
CREATE SEQUENCE ski.seq_id_stand   AS SMALLINT;
CREATE SEQUENCE ski.seq_id_grade   AS SMALLINT;
CREATE SEQUENCE ski.seq_id_technicdecomposition AS SMALLINT;

CREATE SEQUENCE ski.seq_kihon_id_inventory AS SMALLINT;
CREATE SEQUENCE ski.seq_kihon_id_sequence  AS SMALLINT;
CREATE SEQUENCE ski.seq_kihon_id_tx        AS SMALLINT;

CREATE SEQUENCE ski.seq_kata_id_kata     AS SMALLINT;
CREATE SEQUENCE ski.seq_kata_id_sequence AS SMALLINT;
CREATE SEQUENCE ski.seq_kata_id_kswaza   AS SMALLINT;
CREATE SEQUENCE ski.seq_kata_id_tx       AS SMALLINT;

CREATE SEQUENCE ski.seq_bunkai_id_bunkai   AS SMALLINT;
CREATE SEQUENCE ski.seq_bunkai_id_sequence AS SMALLINT;


-- =============================================================
-- Domain Tables (in schema ski)
-- This section defines the main domain tables for the database.
-- =============================================================

-- -------------------------------------------------------------
-- Table: ski.targets
-- Body targets that can be struck.
-- -------------------------------------------------------------
CREATE TABLE ski.targets (
  id_target SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_target'),
  name           VARCHAR(255) NOT NULL,
  original_name  VARCHAR(255),
  description    TEXT,
  notes          TEXT,
  resource_url   TEXT DEFAULT NULL ,
  tsv_name        tsvector GENERATED ALWAYS AS (to_tsvector('simple', name)) STORED,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_targets_name UNIQUE (name)
);

-- -------------------------------------------------------------
-- Table: ski.strikingparts
-- Limbs/parts used to strike.
-- -------------------------------------------------------------
CREATE TABLE ski.strikingparts (
  id_part SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_part'),
  name          VARCHAR(255) NOT NULL,
  translation   VARCHAR(255),
  description   TEXT,
  notes         TEXT,
  resource_url  TEXT DEFAULT NULL ,
  tsv_name        tsvector GENERATED ALWAYS AS (to_tsvector('simple', name) || to_tsvector('simple', translation)) STORED,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_strikingparts_name UNIQUE (name)
);

-- -------------------------------------------------------------
-- Table: ski.technics
-- Inventory of techniques (waza).
-- -------------------------------------------------------------
CREATE TABLE ski.technics (
  id_technic SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_technic'),
  waza         public.waza_type,
  name         VARCHAR(255) NOT NULL,
  description  TEXT,
  notes        TEXT,
  resource_url TEXT DEFAULT NULL ,
  tsv_name        tsvector GENERATED ALWAYS AS (to_tsvector('simple', name)) STORED,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_technics_name UNIQUE (name)
);

-- -------------------------------------------------------------
-- Table: ski.technics_decomposition
-- Explanation of techniques into components (if needed).
-- -------------------------------------------------------------
--da preparare l'insert e l'utilizzo
CREATE TABLE ski.technics_decomposition (
  id_decomposition SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_technicdecomposition'),
  technic_id SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
  component_order SMALLINT NOT NULL,
  description TEXT,
  explatations TEXT, 
  notes TEXT,
  resource_url TEXT DEFAULT NULL ,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_technics_decomposition UNIQUE (technic_id, component_order)
);




-- -------------------------------------------------------------
-- Table: ski.stands
-- Inventory of stances/positions.
-- -------------------------------------------------------------
CREATE TABLE ski.stands (
  id_stand SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_stand'),
  name             VARCHAR(255) NOT NULL,
  description      TEXT,
  illustration_url TEXT,
  notes            TEXT,
  tsv_name        tsvector GENERATED ALWAYS AS (to_tsvector('simple', name)) STORED,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_stands_name UNIQUE (name)
);

-- -------------------------------------------------------------
-- Table: ski.grades
-- Belt grading (kyu/dan) with color.
-- -------------------------------------------------------------
CREATE TABLE ski.grades (
  id_grade SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_grade'),
  gtype public.grade_type NOT NULL,
  grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL,
  color public.beltcolor,
  CONSTRAINT unique_grades_gtype_grade UNIQUE (gtype, grade)
);


-- =============================================================
-- Compendium Tables (Kihon)
-- This section defines tables related to kihon sequences and transitions.
-- =============================================================

-- -------------------------------------------------------------
-- Table: ski.kihon_inventory
-- Normalized inventory of kihon per grade.
-- -------------------------------------------------------------
CREATE TABLE ski.kihon_inventory (
  id_inventory  SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_inventory'),
  grade_id      SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
  number        SMALLINT NOT NULL,
  resources     JSONB  ,
  notes         TEXT,
  tsv_notes     tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_kihon_inventory UNIQUE (grade_id, number)
);

-- -------------------------------------------------------------
-- Table: ski.kihon_sequences
-- Ordered sequence of techniques composing a kihon.
-- -------------------------------------------------------------
CREATE TABLE ski.kihon_sequences (
  id_sequence   SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_sequence'),
  inventory_id  SMALLINT NOT NULL REFERENCES ski.kihon_inventory(id_inventory),
  seq_num       SMALLINT NOT NULL,
  stand_id      SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
  technic_id    SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
  hips          public.hips,
  gyaku         BOOLEAN,
  target_hgt    public.target_hgt,
  resources     JSONB  ,
  notes         TEXT,
  resource_url  TEXT DEFAULT NULL ,
  tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_kihon_sequences UNIQUE (inventory_id, seq_num)
);

-- -------------------------------------------------------------
-- Table: ski.kihon_tx
-- Transitions between kihon steps.
-- -------------------------------------------------------------
CREATE TABLE ski.kihon_tx (
  id_tx SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_tx'),
  from_sequence SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
  to_sequence   SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
  movement      public.movements,
  resources     JSONB  ,
  notes         TEXT,
  tempo         public.tempo,
  resource_url  TEXT DEFAULT NULL ,
  tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_kihon_tx UNIQUE (from_sequence, to_sequence)
);

-- =============================================================
-- Compendium Tables (Kata)
-- This section defines tables related to kata sequences and transitions.
-- =============================================================

-- -------------------------------------------------------------
-- Table: ski.kata_inventory
-- Normalized inventory of kata.
-- -------------------------------------------------------------
CREATE TABLE ski.kata_inventory (
  id_kata SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_kata'),
  kata         VARCHAR(255) NOT NULL,
  serie        public.kata_series,
  starting_leg public.sides NOT NULL,
  notes        TEXT,
  resources      JSONB  ,
  resource_url TEXT DEFAULT NULL ,
  CONSTRAINT unique_kata_inventory_kata UNIQUE (kata)
);

-- -------------------------------------------------------------
-- Table: ski.kata_sequence
-- Normalized kata sequence (positions, directions, etc.).
-- -------------------------------------------------------------
CREATE TABLE ski.kata_sequence (
  id_sequence SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_sequence'),
  kata_id   SMALLINT NOT NULL REFERENCES ski.kata_inventory(id_kata),
  seq_num   SMALLINT NOT NULL,
  stand_id  SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
  speed     public.tempo,
  side      public.sides,
  hips      public.hips,
  embusen   public.embusen_points,
  facing    public.absolute_directions,
  kiai      BOOLEAN,
  notes     TEXT,
  remarks   public.detailednotes[],
  resources   JSONB ,
  resource_url TEXT DEFAULT NULL ,
  tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple', 
    coalesce(notes, '') 
  )) STORED,
  CONSTRAINT unique_kata_sequence UNIQUE (kata_id, seq_num)
);

-- -------------------------------------------------------------
-- Table: ski.kata_sequence_waza
-- Techniques executed on each kata sequence step.
-- -------------------------------------------------------------
CREATE TABLE ski.kata_sequence_waza (
  id_kswaza SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_kswaza'),
  sequence_id       SMALLINT REFERENCES ski.kata_sequence(id_sequence),
  arto              public.bodypart,
  technic_id        SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
  strikingpart_id   SMALLINT REFERENCES ski.strikingparts(id_part),
  technic_target_id SMALLINT REFERENCES ski.targets(id_target),
  notes             TEXT,
  resources           JSONB, 
  tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple', 
    coalesce(notes, '') 
  )) STORED
);

-- -------------------------------------------------------------
-- Table: ski.kata_tx
-- Transitions between kata sequence steps.
-- -------------------------------------------------------------
CREATE TABLE ski.kata_tx (
  id_tx SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_tx'),
  from_sequence SMALLINT NOT NULL,
  to_sequence   SMALLINT NOT NULL,
  tempo public.tempo,
  direction public.sides,
  intermediate_stand_id SMALLINT REFERENCES ski.stands(id_stand),
  --mettere qualcosa 
  notes TEXT,
  remarks public.detailednotes[],
  resources   JSONB  ,
  resource_url TEXT DEFAULT NULL ,
  tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple', 
    coalesce(notes, '') 
  )) STORED,
  CONSTRAINT unique_kata_tx UNIQUE (from_sequence, to_sequence)
);

-- -------------------------------------------------------------
-- Table: ski.bunkai
-- Bunkai (of each step).
-- Valutare come modellare il bunkai, riferito ad ogni singolo step della sequenza del kata, ha senso proporre bunkai "ufficiali" inventati per ogni kata?
-- -------------------------------------------------------------

CREATE TABLE ski.bunkai_inventory (
  id_bunkai SMALLINT PRIMARY KEY,
  kata_id SMALLINT NOT NULL REFERENCES ski.kata_inventory(id_kata),
  version SMALLINT DEFAULT 1,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  notes TEXT,
  resources   JSONB  ,
  resource_url TEXT DEFAULT NULL ,
  CONSTRAINT unique_bunkai_inventory UNIQUE (kata_id, version) 
);


CREATE TABLE ski.bunkai_sequences (
  id_bunkaisequence SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_bunkai_id_sequence'),
  bunkai_id SMALLINT NOT NULL REFERENCES ski.bunkai_inventory(id_bunkai),
  kata_sequence_id SMALLINT NOT NULL REFERENCES ski.kata_sequence(id_sequence),
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources   JSONB  ,
  resource_url TEXT DEFAULT NULL ,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_bunkai_sequence UNIQUE (bunkai_id, kata_sequence_id)
);


-- =============================================================
-- Indexes (FTS + Join helpers)
-- This section creates indexes for full-text search and join optimization.
-- =============================================================

-- FTS indexes
CREATE INDEX idx_targets_tsv_name        ON ski.targets        USING gin (tsv_name);
CREATE INDEX idx_targets_tsv_description ON ski.targets        USING gin (tsv_description);
CREATE INDEX idx_targets_tsv_notes       ON ski.targets        USING gin (tsv_notes);

CREATE INDEX idx_strikingparts_tsv_name        ON ski.strikingparts USING gin (tsv_name);
CREATE INDEX idx_strikingparts_tsv_description ON ski.strikingparts USING gin (tsv_description);
CREATE INDEX idx_strikingparts_tsv_notes       ON ski.strikingparts USING gin (tsv_notes);

CREATE INDEX idx_technics_tsv_name        ON ski.technics USING gin (tsv_name);
CREATE INDEX idx_technics_tsv_description ON ski.technics USING gin (tsv_description);
CREATE INDEX idx_technics_tsv_notes       ON ski.technics USING gin (tsv_notes);

CREATE INDEX idx_stands_tsv_name        ON ski.stands USING gin (tsv_name);
CREATE INDEX idx_stands_tsv_description ON ski.stands USING gin (tsv_description);
CREATE INDEX idx_stands_tsv_notes       ON ski.stands USING gin (tsv_notes);

-- Kihon joins
CREATE INDEX idx_kihon_inventory_grade_id ON ski.kihon_inventory(grade_id);
CREATE INDEX idx_kihon_sequences_inventory_id ON ski.kihon_sequences(inventory_id);
CREATE INDEX idx_kihon_sequences_stand_id ON ski.kihon_sequences(stand_id);
CREATE INDEX idx_kihon_sequences_technic_id ON ski.kihon_sequences(technic_id);

CREATE INDEX idx_kihon_tx_from_sequence ON ski.kihon_tx(from_sequence);
CREATE INDEX idx_kihon_tx_to_sequence   ON ski.kihon_tx(to_sequence);

-- Kata joins
CREATE INDEX idx_kata_sequence_kata_id ON ski.kata_sequence(kata_id);
CREATE INDEX idx_kata_sequence_stand_id ON ski.kata_sequence(stand_id);

CREATE INDEX idx_kata_waza_sequence_id     ON ski.kata_sequence_waza(sequence_id);
CREATE INDEX idx_kata_waza_technic_id      ON ski.kata_sequence_waza(technic_id);
CREATE INDEX idx_kata_waza_strikingpart_id ON ski.kata_sequence_waza(strikingpart_id);
CREATE INDEX idx_kata_waza_target_id       ON ski.kata_sequence_waza(technic_target_id);

CREATE INDEX idx_kata_tx_from_sequence        ON ski.kata_tx(from_sequence);
CREATE INDEX idx_kata_tx_to_sequence          ON ski.kata_tx(to_sequence);
CREATE INDEX idx_kata_tx_intermediate_stand_id   ON ski.kata_tx(intermediate_stand_id);

-- Lookup indexes
CREATE INDEX idx_targets_name         ON ski.targets(name);
CREATE INDEX idx_strikingparts_name   ON ski.strikingparts(name);
CREATE INDEX idx_technics_name        ON ski.technics(name);
CREATE INDEX idx_stands_name          ON ski.stands(name);
CREATE INDEX idx_kata_inventory_name  ON ski.kata_inventory(kata);
CREATE INDEX idx_grades_gtype         ON ski.grades(gtype);
CREATE INDEX idx_kata_sequence_side   ON ski.kata_sequence(side);
CREATE INDEX idx_kata_sequence_facing ON ski.kata_sequence(facing);


-- =============================================================
-- Functions 
-- This section defines functions for retrieving and manipulating data.
-- tabelle con remarks & resources: ski.kata_inventory ski.kata_sequence ski.kata_sequence_waza ski.kata_tx
-- =============================================================

-- Return the id_grade for (grade, type)
CREATE OR REPLACE FUNCTION public.get_gradeid(_grade INT, _type VARCHAR)
RETURNS SMALLINT
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_grade
  FROM ski.grades
  WHERE grade = _grade
    AND gtype = _type::public.grade_type;
$Func$;

-- List kihon inventory rows for a given (grade, type)
CREATE OR REPLACE FUNCTION public.get_kihons(_grade INT, _type VARCHAR)
RETURNS TABLE(id_inventory INT, grade_id INT, number INT , notes TEXT)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_inventory, grade_id, number , notes
  FROM ski.kihon_inventory
  WHERE grade_id = public.get_gradeid(_grade, _type);
$Func$;

-- Get kihon inventory id by (grade_id, sequence number)
CREATE OR REPLACE FUNCTION public.get_kihonid(_gradeid INT, _num INT)
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_inventory FROM ski.kihon_inventory
  WHERE grade_id = _gradeid AND number = _num;
$Func$;

-- Technique info
CREATE OR REPLACE FUNCTION public.get_technic_info(_technic_id INT)
RETURNS TABLE (
  id_technic SMALLINT,
  waza public.waza_type,
  name TEXT,
  description TEXT,
  notes TEXT,
  resource_url TEXT DEFAULT NULL 
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_technic, waza, name, description, notes, resource_url
  FROM ski.technics
  WHERE id_technic = _technic_id;
$Func$;

-- Stand info
CREATE OR REPLACE FUNCTION public.get_stand_info(_stand_id INT)
RETURNS TABLE (
  id_stand SMALLINT,
  name TEXT,
  description TEXT,
  illustration_url TEXT,
  notes TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_stand, name, description, illustration_url, notes
  FROM ski.stands
  WHERE id_stand = _stand_id;
$Func$;

-- Strikingpart info
CREATE OR REPLACE FUNCTION public.get_strikingparts_info(_id_part INT)
RETURNS TABLE (
  id_part SMALLINT,
  name TEXT,
  translation TEXT,
  description TEXT,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_part, name, translation, description, notes, resource_url
  FROM ski.strikingparts
  WHERE id_part = _id_part;
$Func$;

-- Target info
CREATE OR REPLACE FUNCTION public.get_target_info(_id_target INT)
RETURNS TABLE (
  id_target SMALLINT,
  name TEXT,
  original_name TEXT,
  description TEXT,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_target, name, original_name, description, notes, resource_url
  FROM ski.targets
  WHERE id_target = _id_target;
$Func$;

-- Kata sequence with aggregated waza (one row per step)
CREATE OR REPLACE FUNCTION public.get_katasequence(_kata_id INT)
RETURNS TABLE (
  id_sequence SMALLINT,
  kata_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  posizione TEXT,
  guardia public.sides,
  facing public.absolute_directions,
  Tecniche JSON,
  embusen public.embusen_points,
  kiai BOOLEAN,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT seq.id_sequence,
         seq.kata_id,
         seq.seq_num,
         seq.stand_id,
         MAX(stands.name) AS posizione,
         seq.side AS guardia,
         seq.facing,
         json_agg(
           json_build_object(
             'sequence_id', combo.sequence_id,
             'arto', combo.arto,
             'technic_id', combo.technic_id,
             'Tecnica', combo.technic_name,
             'technic_target_id', combo.technic_target_id,
             'Obiettivo', combo.target_name,
             'waza_note', combo.waza_note,
             --'waza_remarks', combo.waza_remarks,
             'waza_resources', combo.waza_resources
           )
         ) AS Tecniche,
         seq.embusen,
         seq.kiai,
         seq.notes,
         seq.remarks,
         seq.resources,
         seq.resource_url
  FROM ski.kata_sequence AS seq
  JOIN (
    SELECT combo_raw.id_kswaza,
           combo_raw.sequence_id,
           combo_raw.arto,
           combo_raw.technic_id,
           combo_raw.technic_target_id,
           combo_raw.notes,
           tech.name AS technic_name,
           targets.name AS target_name,
           combo_raw.notes AS waza_note,
           --combo_raw.remarks AS waza_remarks,
           combo_raw.resources AS waza_resources
    FROM ski.kata_sequence_waza AS combo_raw
    JOIN ski.technics AS tech
      ON combo_raw.technic_id = tech.id_technic
    LEFT JOIN ski.targets AS targets
      ON combo_raw.technic_target_id = targets.id_target
  ) AS combo
    ON seq.id_sequence = combo.sequence_id
  LEFT JOIN ski.stands AS stands
    ON seq.stand_id = stands.id_stand
  WHERE seq.kata_id = _kata_id
  GROUP BY seq.id_sequence
  ORDER BY seq.seq_num;
$Func$;

-- Kata transitions filtered by kata_id
CREATE OR REPLACE FUNCTION public.get_katatx(_kata_id INT)
RETURNS TABLE (
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  tempo public.tempo,
  direction public.sides,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH relevantseq AS (
    SELECT id_sequence FROM ski.kata_sequence WHERE kata_id = _kata_id
  )
  SELECT id_tx,
         from_sequence,
         to_sequence,
         tempo,
         direction,
         notes,
         remarks,
         resources,
         resource_url
  FROM ski.kata_tx
  WHERE from_sequence IN (SELECT id_sequence FROM relevantseq)
     OR to_sequence   IN (SELECT id_sequence FROM relevantseq);
$Func$;

-- Kihon steps for a given (grade_id, sequence number)
CREATE OR REPLACE FUNCTION public.get_kihon_steps(_grade_id INT, _sequenza INT)
RETURNS TABLE (
  id_sequence SMALLINT,
  inventory_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  technic_id SMALLINT,
  gyaku BOOLEAN,
  target_hgt public.target_hgt,
  notes TEXT,
  resource_url TEXT,
  stand_name TEXT,
  technic_name TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT seq.id_sequence,
         seq.inventory_id,
         seq.seq_num,
         seq.stand_id,
         seq.technic_id,
         seq.gyaku,
         seq.target_hgt,
         seq.notes,
         seq.resource_url,
         stand.name AS stand_name,
         technic.name AS technic_name
  FROM ski.kihon_sequences AS seq
  JOIN ski.kihon_inventory AS inv
    ON seq.inventory_id = inv.id_inventory
  LEFT JOIN ski.stands AS stand
    ON seq.stand_id = stand.id_stand
  LEFT JOIN ski.technics AS technic
    ON seq.technic_id = technic.id_technic
  WHERE inv.grade_id = _grade_id
    AND inv.number   = _sequenza
  ORDER BY seq.seq_num;
$Func$;

-- Kihon transitions for a given (grade_id, sequence number)
CREATE OR REPLACE FUNCTION public.get_kihon_tx(_grade_id INT, _sequenza INT)
RETURNS TABLE (
  id_tx SMALLINT,
  from_sequence SMALLINT,
  to_sequence SMALLINT,
  movement public.movements,
  tempo public.tempo,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH relevant_sequences AS (
    SELECT seq.id_sequence
    FROM ski.kihon_sequences AS seq
    JOIN ski.kihon_inventory AS inv
      ON seq.inventory_id = inv.id_inventory
    WHERE inv.grade_id = _grade_id
      AND inv.number   = _sequenza
  )
  SELECT tx.id_tx,
         tx.from_sequence,
         tx.to_sequence,
         tx.movement,
         tx.tempo,
         tx.notes,
         tx.resource_url
  FROM ski.kihon_tx AS tx
  WHERE tx.from_sequence IN (SELECT id_sequence FROM relevant_sequences)
     OR tx.to_sequence   IN (SELECT id_sequence FROM relevant_sequences)
  ORDER BY tx.from_sequence;
$Func$;

-- Kihon "formatted list" for a grade
CREATE OR REPLACE FUNCTION public.kihon_frmlist(_grade_id INT)
RETURNS TABLE (
  number SMALLINT,
  seq_num SMALLINT,
  movement public.movements,
  technic_id SMALLINT,
  gyaku BOOLEAN,
  tecnica TEXT,
  stand_id SMALLINT,
  posizione TEXT,
  target_hgt public.target_hgt,
  notes TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT 
    inv.number,
    seq.seq_num,
    tx.movement,
    seq.technic_id,
    seq.gyaku,
    CASE WHEN seq.gyaku THEN CONCAT('(Gyaku) ', tech.name) ELSE tech.name END AS tecnica,
    seq.stand_id,
    stands.name AS posizione,
    seq.target_hgt,
    seq.notes
  FROM ski.kihon_sequences AS seq
  INNER JOIN ski.kihon_inventory AS inv
    ON seq.inventory_id = inv.id_inventory
  LEFT JOIN ski.kihon_tx AS tx 
    ON seq.id_sequence = tx.to_sequence
  LEFT JOIN ski.technics AS tech
    ON seq.technic_id = tech.id_technic
  LEFT JOIN ski.stands AS stands
    ON seq.stand_id = stands.id_stand
  WHERE inv.grade_id = _grade_id
    AND seq.seq_num <> 0
  ORDER BY inv.number, seq.seq_num;
$Func$;

-- new func

CREATE OR REPLACE FUNCTION public.get_nkihon(_grade_id INT)
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT MAX(number) AS nkihon
    FROM ski.kihon_inventory
    WHERE grade_id = _grade_id
    GROUP BY grade_id;
$Func$;

CREATE OR REPLACE FUNCTION public.get_grade(_grade_id INT)
RETURNS TABLE (
    grade SMALLINT,
    gtype public.grade_type
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT grade, gtype
    FROM ski.grades
    WHERE id_grade = _grade_id;
$Func$;

CREATE OR REPLACE FUNCTION public.get_technics()
RETURNS TABLE (
    id_technic SMALLINT,
    waza public.waza_type,
    name TEXT,
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_technic, waza, name, description, notes, resource_url
    FROM ski.technics
    WHERE waza <> '_'::waza_type ;
$Func$;

CREATE OR REPLACE FUNCTION public.get_stands()
RETURNS TABLE (
    id_stand SMALLINT,
    name TEXT,
    description TEXT,
    illustration_url TEXT,
    notes TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_stand, name, description, illustration_url, notes
    FROM ski.stands;
$Func$;

CREATE OR REPLACE FUNCTION public.get_targets()
RETURNS TABLE (
    id_target SMALLINT,
    name TEXT,
    original_name TEXT,
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_target, name, original_name, description, notes, resource_url
    FROM ski.targets;
$Func$;

CREATE OR REPLACE FUNCTION public.get_strikingparts()
RETURNS TABLE (
    id_part SMALLINT,
    name TEXT,
    translation TEXT,
    description TEXT,
    notes TEXT,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_part, name, translation, description, notes, resource_url
    FROM ski.strikingparts;
$Func$;


CREATE OR REPLACE FUNCTION public.get_katainfo(_kata_id INT)
RETURNS TABLE (
    kata VARCHAR,
    serie public.kata_series,
    starting_leg public.sides,
    notes TEXT,
    remarks public.detailednotes[],
    resources JSONB,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT kata, serie, starting_leg, notes, remarks, resources, resource_url
    FROM ski.kata_inventory
    WHERE id_kata = _kata_id;
$Func$;

CREATE OR REPLACE FUNCTION public.show_gradeinventory()
RETURNS TABLE (
    grade SMALLINT,
    gtype public.grade_type,
    id_grade SMALLINT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT grade, gtype, id_grade
    FROM ski.grades;
$Func$;

CREATE OR REPLACE FUNCTION public.show_katainventory()
RETURNS TABLE (
    id_kata SMALLINT,
    kata VARCHAR,
    serie public.kata_series,
    starting_leg public.sides,
    notes TEXT,
    remarks public.detailednotes[],
    resources JSONB,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_kata, kata, serie, starting_leg, notes, remarks, resources, resource_url
    FROM ski.kata_inventory;
$Func$;


CREATE OR REPLACE FUNCTION public.get_kihonnotes(_gradeid INT, _num INT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT notes 
  FROM ski.kihon_inventory
  WHERE grade_id = _gradeid AND number = _num;
$Func$;

CREATE FUNCTION public.get_bunkainum(_kata_id INT)
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT COUNT(*) AS nbunkai
    FROM ski.bunkai_inventory
    WHERE kata_id = _kata_id
    GROUP BY kata_id;
$Func$;

CREATE OR REPLACE FUNCTION public.get_katabunkais(_kata_id INT)
RETURNS TABLE (
    id_bunkai SMALLINT,
    kata_id SMALLINT,
    version SMALLINT,
    name VARCHAR,
    description TEXT,
    notes TEXT,
    resources JSONB,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_bunkai, kata_id, version, name, description, notes, resources, resource_url
    FROM ski.bunkai_inventory
    WHERE kata_id = _kata_id;
$Func$;

SELECT id_bunkai,version,name,description,notes,resources FROM public.get_katabunkais(1);

CREATE OR REPLACE FUNCTION public.get_bunkai(_bunkai_id INT)
RETURNS TABLE (
  id_bunkaisequence SMALLINT ,
  bunkai_id SMALLINT ,
  kata_sequence_id SMALLINT ,
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_bunkaisequence, bunkai_id, kata_sequence_id, description, notes, remarks, resources, resource_url
  FROM ski.bunkai_sequences
  WHERE bunkai_id = _bunkai_id;
$Func$;


CREATE OR REPLACE FUNCTION public.get_bunkais(_kata_id INT)
RETURNS TABLE (
  id_bunkaisequence SMALLINT ,
  bunkai_id SMALLINT ,
  version SMALLINT ,
  kata_sequence_id SMALLINT ,
  description TEXT,
  notes TEXT,
  remarks public.detailednotes[],
  resources JSONB,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH 
    bunkai_ids AS (
      SELECT id_bunkai as bunkai_id, version
      FROM ski.bunkai_inventory
      WHERE kata_id = _kata_id
    )
  SELECT base.id_bunkaisequence, base.bunkai_id,bunkai_ids.version, base.kata_sequence_id, base.description, base.notes, base.remarks, base.resources, base.resource_url
  FROM ski.bunkai_sequences AS base
  INNER JOIN bunkai_ids
  ON base.bunkai_id = bunkai_ids.bunkai_id;
$Func$;

-- Text search helpers (targets/technics/stands/strikingparts)
CREATE OR REPLACE FUNCTION ski.get_ts_targets(_search TEXT)
RETURNS TABLE(id SMALLINT, name_rank FLOAT, description_rank FLOAT, notes_rank FLOAT)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH tsearch AS (
    SELECT id_target AS id,
           ts_rank_cd(tsv_name,        websearch_to_tsquery('simple', _search), 16) AS name_rank,
           ts_rank_cd(tsv_description, websearch_to_tsquery('simple', _search), 16) AS description_rank,
           ts_rank_cd(tsv_notes,       websearch_to_tsquery('simple', _search), 16) AS notes_rank
    FROM ski.targets
  )
  SELECT id, name_rank, description_rank, notes_rank
  FROM tsearch
  WHERE name_rank > 0 OR description_rank > 0 OR notes_rank > 0
  ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
$Func$;

CREATE OR REPLACE FUNCTION ski.get_ts_technics(_search TEXT)
RETURNS TABLE(id SMALLINT, name_rank FLOAT, description_rank FLOAT, notes_rank FLOAT)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH tsearch AS (
    SELECT id_technic AS id,
           ts_rank_cd(tsv_name,        websearch_to_tsquery('simple', _search), 16) AS name_rank,
           ts_rank_cd(tsv_description, websearch_to_tsquery('simple', _search), 16) AS description_rank,
           ts_rank_cd(tsv_notes,       websearch_to_tsquery('simple', _search), 16) AS notes_rank
    FROM ski.technics
  )
  SELECT id, name_rank, description_rank, notes_rank
  FROM tsearch
  WHERE name_rank > 0 OR description_rank > 0 OR notes_rank > 0
  ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
$Func$;

CREATE OR REPLACE FUNCTION ski.get_ts_stands(_search TEXT)
RETURNS TABLE(id SMALLINT, name_rank FLOAT, description_rank FLOAT, notes_rank FLOAT)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH tsearch AS (
    SELECT id_stand AS id,
           ts_rank_cd(tsv_name,        websearch_to_tsquery('simple', _search), 16) AS name_rank,
           ts_rank_cd(tsv_description, websearch_to_tsquery('simple', _search), 16) AS description_rank,
           ts_rank_cd(tsv_notes,       websearch_to_tsquery('simple', _search), 16) AS notes_rank
    FROM ski.stands
  )
  SELECT id, name_rank, description_rank, notes_rank
  FROM tsearch
  WHERE name_rank > 0 OR description_rank > 0 OR notes_rank > 0
  ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
$Func$;

CREATE OR REPLACE FUNCTION ski.get_ts_strikingparts(_search TEXT)
RETURNS TABLE(id SMALLINT, name_rank FLOAT, description_rank FLOAT, notes_rank FLOAT)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH tsearch AS (
    SELECT id_part AS id,
           ts_rank_cd(tsv_name,        websearch_to_tsquery('simple', _search), 16) AS name_rank,
           ts_rank_cd(tsv_description, websearch_to_tsquery('simple', _search), 16) AS description_rank,
           ts_rank_cd(tsv_notes,       websearch_to_tsquery('simple', _search), 16) AS notes_rank
    FROM ski.strikingparts
  )
  SELECT id, name_rank, description_rank, notes_rank
  FROM tsearch
  WHERE name_rank > 0 OR description_rank > 0 OR notes_rank > 0
  ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
$Func$;

-- Rank normalizer
CREATE OR REPLACE FUNCTION ski.ts_normalizer(
  _name_rank FLOAT,
  _description_rank FLOAT,
  _notes_rank FLOAT,
  _name_wht FLOAT DEFAULT 1.0,
  _description_wht FLOAT DEFAULT 0.75,
  _notes_wht FLOAT DEFAULT 0.25
)
RETURNS FLOAT
LANGUAGE sql 
SECURITY DEFINER
IMMUTABLE PARALLEL SAFE
AS $Func$
  SELECT coalesce(_name_rank, 0) * _name_wht
       + coalesce(_description_rank, 0) * _description_wht
       + coalesce(_notes_rank, 0) * _notes_wht;
$Func$;

CREATE OR REPLACE FUNCTION public.qry_ts_targets(
  _search TEXT,
  _name_wht FLOAT DEFAULT 1.0,
  _description_wht FLOAT DEFAULT 0.75,
  _notes_wht FLOAT DEFAULT 0.25
)
RETURNS TABLE (
  pertinenza FLOAT,
  pertinenza_relativa FLOAT,
  id_target SMALLINT,
  name VARCHAR,
  original_name VARCHAR,
  description TEXT,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH ts AS (
    SELECT id,
           ski.ts_normalizer(name_rank, description_rank, notes_rank,
                             _name_wht, _description_wht, _notes_wht) AS pertinenza
    FROM ski.get_ts_targets(_search)
  )
  SELECT ts.pertinenza,
         ts.pertinenza / (SELECT MAX(pertinenza) FROM ts),
         tbl.id_target, tbl.name, tbl.original_name,
         tbl.description, tbl.notes, tbl.resource_url
  FROM ts
  INNER JOIN ski.targets AS tbl ON ts.id = tbl.id_target
  ORDER BY pertinenza DESC;
$Func$;

CREATE OR REPLACE FUNCTION public.qry_ts_technics(
  _search TEXT,
  _name_wht FLOAT DEFAULT 1.0,
  _description_wht FLOAT DEFAULT 0.75,
  _notes_wht FLOAT DEFAULT 0.25
)
RETURNS TABLE (
  pertinenza FLOAT,
  pertinenza_relativa FLOAT,
  id_technic SMALLINT,
  waza public.waza_type,
  name VARCHAR,
  description TEXT,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH ts AS (
    SELECT id,
           ski.ts_normalizer(name_rank, description_rank, notes_rank,
                             _name_wht, _description_wht, _notes_wht) AS pertinenza
    FROM ski.get_ts_technics(_search)
    ORDER BY pertinenza
  )
  SELECT ts.pertinenza,
         ts.pertinenza / (SELECT MAX(pertinenza) FROM ts),
         tbl.id_technic, tbl.waza, tbl.name,
         tbl.description, tbl.notes, tbl.resource_url
  FROM ts
  INNER JOIN ski.technics AS tbl ON ts.id = tbl.id_technic;
$Func$;

CREATE OR REPLACE FUNCTION public.qry_ts_stands(
  _search TEXT,
  _name_wht FLOAT DEFAULT 1.0,
  _description_wht FLOAT DEFAULT 0.75,
  _notes_wht FLOAT DEFAULT 0.25
)
RETURNS TABLE (
  pertinenza FLOAT,
  pertinenza_relativa FLOAT,
  id_stand SMALLINT,
  name VARCHAR,
  description TEXT,
  illustration_url TEXT,
  notes TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH ts AS (
    SELECT id,
           ski.ts_normalizer(name_rank, description_rank, notes_rank,
                             _name_wht, _description_wht, _notes_wht) AS pertinenza
    FROM ski.get_ts_stands(_search)
    ORDER BY pertinenza
  )
  SELECT ts.pertinenza,
         ts.pertinenza / (SELECT MAX(pertinenza) FROM ts),
         tbl.id_stand, tbl.name, tbl.description,
         tbl.illustration_url, tbl.notes
  FROM ts
  INNER JOIN ski.stands AS tbl ON ts.id = tbl.id_stand;
$Func$;

CREATE OR REPLACE FUNCTION public.qry_ts_strikingparts(
  _search TEXT,
  _name_wht FLOAT DEFAULT 1.0,
  _description_wht FLOAT DEFAULT 0.75,
  _notes_wht FLOAT DEFAULT 0.25
)
RETURNS TABLE (
  pertinenza FLOAT,
  pertinenza_relativa FLOAT,
  id_part SMALLINT,
  name VARCHAR,
  translation VARCHAR,
  description TEXT,
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  WITH ts AS (
    SELECT id,
           ski.ts_normalizer(name_rank, description_rank, notes_rank,
                             _name_wht, _description_wht, _notes_wht) AS pertinenza
    FROM ski.get_ts_strikingparts(_search)
    ORDER BY pertinenza
  )
  SELECT ts.pertinenza,
         ts.pertinenza / (SELECT MAX(pertinenza) FROM ts),
         tbl.id_part, tbl.name, tbl.translation,
         tbl.description, tbl.notes, tbl.resource_url
  FROM ts
  INNER JOIN ski.strikingparts AS tbl ON ts.id = tbl.id_part;
$Func$;

-- 

CREATE FUNCTION public.get_technicdecomposition(_technic_id INT)
RETURNS TABLE (
  id_decomposition SMALLINT,
  technic_id SMALLINT,
  component_order SMALLINT,
  description TEXT,
  explatations TEXT, 
  notes TEXT,
  resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
  SELECT id_decomposition, technic_id, component_order, description, explatations, notes, resource_url
  FROM ski.technics_decomposition
  WHERE technic_id = _technic_id
  ORDER BY component_order;
$Func$;

CREATE FUNCTION public.info_kata(_kata_id INT)
RETURNS TABLE (
  id_sequence SMALLINT,
  kata_id SMALLINT,
  seq_num SMALLINT,
  stand_id SMALLINT,
  stand_name TEXT,
  speed public.tempo,
  side public.sides,
  hips public.hips,
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai BOOLEAN,
  notes TEXT,
  Tecniche JSON
)
LANGUAGE sql
SECURITY DEFINER
AS $$
SELECT ks.id_sequence,
ks.kata_id,
ks.seq_num,
ks.stand_id,
MAX(stand.name) as stand_name,
ks.speed,
ks.side, 
ks.hips,
ks.embusen,
ks.facing, 
ks.kiai,
ks.notes,
json_agg(
  json_build_object(
    'sequence_id', combo.sequence_id,
    'arto', combo.arto,
    'technic_id', combo.technic_id,
    'Tecnica', combo.technic_name,
    'technic_target_id', combo.technic_target_id,
    'Obiettivo', combo.target_name,
    'waza_note', combo.waza_note,
    --'waza_remarks', combo.waza_remarks,
    'waza_resources', combo.waza_resources
  )
) AS Tecniche
FROM ski.kata_sequence AS ks
LEFT JOIN ski.stands AS stand
ON stand.id_stand = ks.stand_id
JOIN (
  SELECT combo_raw.id_kswaza,
          combo_raw.sequence_id,
          combo_raw.arto,
          combo_raw.technic_id,
          combo_raw.technic_target_id,
          combo_raw.notes,
          tech.name AS technic_name,
          targets.name AS target_name,
          combo_raw.notes AS waza_note,
          --combo_raw.remarks AS waza_remarks,
          combo_raw.resources AS waza_resources
  FROM ski.kata_sequence_waza AS combo_raw
  JOIN ski.technics AS tech
    ON combo_raw.technic_id = tech.id_technic
  LEFT JOIN ski.targets AS targets
    ON combo_raw.technic_target_id = targets.id_target
) AS combo
  ON ks.id_sequence = combo.sequence_id
WHERE ks.kata_id = _kata_id
GROUP BY ks.id_sequence
;
$$;


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
  hips public.hips,
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
  remarks public.detailednotes[],
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
  hips public.hips,
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
  notes TEXT,
  remarks public.detailednotes[],
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
  remarks public.detailednotes[],
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
  remarks public.detailednotes[],
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
  hips public.hips,
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
  remarks public.detailednotes[],
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
  hips public.hips,
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
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

CREATE TABLE upsert.kata_sequence_waza(
  id_kswaza SMALLINT,
  sequence_id SMALLINT,
  arto public.bodypart,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  remarks public.detailednotes[],
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
  remarks public.detailednotes[],
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
  hips public.hips,
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
  remarks public.detailednotes[],
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
  hips public.hips,
  embusen public.embusen_points,
  facing public.absolute_directions,
  kiai bool,
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

CREATE TABLE reject.kata_sequence_waza(
  id_kswaza SMALLINT,
  sequence_id SMALLINT,
  arto public.bodypart,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  remarks public.detailednotes[],
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
  remarks public.detailednotes[],
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
CREATE OR REPLACE PROCEDURE staging.clean(_ts integer)
  LANGUAGE SQL AS 
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
    sequence_id SMALLINT ,
    arto arti,
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
        bkp  ,
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
        hips,
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
        hips,
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
        remarks,
        resources,
        resource_url 
    ) SELECT tms_op ,
        id_kata ,
        kata  ,
        serie ,
        starting_leg ,
        notes ,
        remarks,
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
        hips,
        embusen ,
        facing , 
        kiai ,
        notes ,
        remarks,
        resources,
        resource_url 
    ) SELECT tms_op ,
        id_sequence  ,
        kata_id  ,
        seq_num  ,
        stand_id  ,
        speed ,
        side ,
        hips,
        embusen ,
        facing , 
        kiai,
        notes ,
        remarks,
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
        remarks,
        resources
    ) SELECT tms_op ,
        id_kswaza  ,
        sequence_id  ,
        arto ,
        technic_id  ,
        strikingpart_id  ,
        technic_target_id  ,
        notes ,
        remarks,
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
        remarks,
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
        remarks,
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