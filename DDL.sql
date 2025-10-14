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
-- Compendium Tables (Fundamentals)
-- This section defines tables related to fundamentals
-- =============================================================


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
  explanations TEXT, 
  resources     JSONB  ,
  notes TEXT,
  resource_url TEXT DEFAULT NULL ,
  tsv_description tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
  tsv_notes       tsvector GENERATED ALWAYS AS (to_tsvector('simple', notes)) STORED,
  CONSTRAINT unique_technics_decomposition UNIQUE (technic_id, component_order)
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
  hips          public.hips, -- Hanmi, Shomen
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
  resource_url TEXT 
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
  stand_id SMALLINT, -- Posizione
  posizione TEXT,
  speed public.tempo,
  guardia public.sides,
  hips public.hips,
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
         seq.speed,
         seq.side AS guardia, -- lato della guardia
         seq.hips,
         seq.facing,
         json_agg(
           json_build_object(
             'sequence_id', combo.sequence_id,
             'arto', combo.arto,
             'technic_id', combo.technic_id,
             'Tecnica', combo.technic_name,
             'strikingpart_id', combo.strikingpart_id,
             'strikingpart_name', combo.strikingpart_name,
             'technic_target_id', combo.technic_target_id,
             'Obiettivo', combo.target_name,
             'waza_note', combo.notes,
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
    SELECT combo_raw.sequence_id,
           combo_raw.arto,
           combo_raw.technic_id,
           combo_raw.strikingpart_id,
           combo_raw.technic_target_id,
           combo_raw.notes,
           tech.name AS technic_name,
           sp.name as strikingpart_name,
           targets.name AS target_name,
           combo_raw.resources AS waza_resources
    FROM ski.kata_sequence_waza AS combo_raw
    JOIN ski.technics AS tech
      ON combo_raw.technic_id = tech.id_technic
    LEFT JOIN ski.strikingparts AS sp
      ON combo_raw.strikingpart_id = sp.id_part
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
  intermediate_stand_id SMALLINT,
  notes TEXT,
  -- remarks public.detailednotes[], -- Temporarily removed
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
         intermediate_stand_id,
         notes, 
         -- remarks, -- Temporarily removed
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
  resources JSONB,
  notes TEXT,
  tempo public.tempo,
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
         tx.resources,
         tx.notes,
         tx.tempo,
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
    resources JSONB,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT kata, serie, starting_leg, notes, resources, resource_url
    FROM ski.kata_inventory -- The 'remarks' column was removed from ski.kata_inventory
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
    -- remarks public.detailednotes[], -- Temporarily removed
    resources JSONB,
    resource_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $Func$
    SELECT id_kata, kata, serie, starting_leg, notes, resources, resource_url
    FROM ski.kata_inventory; -- The 'remarks' column was removed from ski.kata_inventory
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
  -- hips public.hips, -- Temporarily removed
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
-- ks.hips, -- Temporarily removed
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

