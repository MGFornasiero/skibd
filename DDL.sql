DROP SCHEMA ski CASCADE;
CREATE SCHEMA ski;

CREATE TYPE ski.grade_type AS ENUM (
    'kyu',
    'dan'
);
CREATE TYPE ski.sides AS ENUM (
    'sx',
    'frontal',
    'dx'
);
CREATE TYPE ski.movements AS ENUM(
    'Fwd',
    'Still',
    'Bkw'
);
CREATE TYPE ski.kata_series AS ENUM (
    'Heian',
    'Tekki',
    'Sentei'
);
CREATE TYPE ski.target_hgt AS ENUM(
    'Jodan',
    'Chudan',
    'Gedan'
);
CREATE TYPE ski.waza_type AS ENUM(
    'Uke',
    'Uchi',
    'Geri',
    'NA',
    '_'
);
CREATE TYPE ski.tempo AS ENUM(
    'Legato',
    'Fast',
    'Normal',
    'Slow',
    'Breath'
);

CREATE TYPE ski.embusen_points AS (
    x SMALLINT,
    y SMALLINT
); -- Definisce la posizione nello spazio come piano cartesiano con 0 in posizione del saluto

CREATE TYPE ski.arti AS ENUM(
    'Braccio DX',
    'Braccio SX',
    'Braccia',
    'Gamba DX',
    'Gamba SX',
    'Gambe',
    'NA'
);

CREATE TYPE ski.beltcolor AS ENUM(
    'bianco',
    'giallo',
    'arancio',
    'verde',
    'blu',
    'nero'
); -- Colori delle cinture

CREATE TYPE ski.absolute_directions AS ENUM(
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SO',
    'O',
    'NO'
); -- Direzione assoluta rispetto al saluto inizale

CREATE SEQUENCE ski.seq_id_target AS SMALLINT ;
CREATE SEQUENCE ski.seq_id_part AS SMALLINT ;
CREATE SEQUENCE ski.seq_id_technic AS SMALLINT ;
CREATE SEQUENCE ski.seq_id_stand AS SMALLINT ;
CREATE SEQUENCE ski.seq_id_grade AS SMALLINT ;

CREATE SEQUENCE ski.seq_kihon_id_inventory AS SMALLINT ;
CREATE SEQUENCE ski.seq_kihon_id_sequence AS SMALLINT ;
CREATE SEQUENCE ski.seq_kihon_id_tx AS SMALLINT ;


CREATE SEQUENCE ski.seq_kata_id_kata AS SMALLINT ;
CREATE SEQUENCE ski.seq_kata_id_sequence AS SMALLINT ;
CREATE SEQUENCE ski.seq_kata_id_kswaza AS SMALLINT ;
CREATE SEQUENCE ski.seq_kata_id_tx AS SMALLINT ;

--                                      DOMANINS TABLE

CREATE TABLE ski.targets(
    id_target SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_target'),
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

CREATE TABLE ski.strikingparts( 
    id_part SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_part'),
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

CREATE TABLE ski.technics(
    id_technic SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_technic'),
    waza ski.waza_type,
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

CREATE TABLE ski.stands(
    id_stand SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_stand'),
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

CREATE TABLE ski.grades(
    id_grade SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_id_grade'),
    gtype ski.grade_type NOT NULL,
    grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
    color ski.beltcolor,
    CONSTRAINT unique_grade UNIQUE (gtype, grade)
); -- forma normale della sequenza di gradi Kiu e Dan


--                                      COMPENDIUM TABLES

CREATE TABLE ski.kihon_inventory(
    id_inventory SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_inventory'),
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    notes TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
); -- Inventario in forma normale con i kihon per ciascuna cintura

CREATE TABLE ski.kihon_sequences(
    id_sequence SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_sequence'),
    inventory_id SMALLINT NOT NULL REFERENCES ski.kihon_inventory(id_inventory),
    seq_num SMALLINT NOT NULL, -- Posizione ordinale nella sequenza
    stand SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
    techinc SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
    gyaku bool,
    target_hgt ski.target_hgt ,
    notes TEXT ,
    resource_url TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_kihonsequence UNIQUE (inventory_id, seq_num)
); --Sequenza delle tecniche che compongono i kihon

CREATE TABLE ski.kihon_tx(
    id_tx SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kihon_id_tx'),
    from_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence), 
    to_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    movement ski.movements ,
    notes TEXT,
    tempo ski.tempo ,
    resource_url TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
); --Passaggio da una tecnica all' altra 

CREATE TABLE ski.Kata_inventory(
    id_kata SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_kata'),
    kata VARCHAR(255) NOT NULL,
    serie ski.kata_series,
    starting_leg ski.sides NOT NULL,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata UNIQUE (kata)
); -- Inventario in forma normale dei kata

CREATE TABLE ski.kata_sequence(
    id_sequence SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_sequence'),
    kata_id SMALLINT NOT NULL REFERENCES ski.Kata_inventory(id_kata),
    seq_num SMALLINT NOT NULL,
    stand_id SMALLINT NOT NULL REFERENCES ski.stands(id_stand),
    speed ski.tempo ,
    side ski.sides, -- lato della guardia
    embusen ski.embusen_points ,
    facing ski.absolute_directions, -- direzioni cardinali rispetto all' inizio
    kiai bool,
    notes TEXT,
    resource_url TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED,
    CONSTRAINT unique_kata_seq UNIQUE (kata_id, seq_num)
); -- Sequenza in forma normale del kata
--le tecniche da eseguire sono nella tabella ski.kata_sequence_waza per rispettare forma normale potendo essercene più d'una.
--La forma corretta sarebbe avere ulteriore tabella di raccordo 1:n ma occorrerebbe ulteriore logica applicativa
-- Un alternativa sarebbe un tipo array ma non sarebbero disponibili i constraint e le ricerche.

CREATE TABLE ski.kata_sequence_waza (
    id_kswaza SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_kswaza'),
    sequence_id SMALLINT REFERENCES ski.kata_sequence(id_sequence),
    arto ski.arti,
    technic_id SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
    strikingpart_id SMALLINT REFERENCES ski.strikingparts(id_part),
    technic_target_id SMALLINT REFERENCES ski.targets(id_target),
    notes TEXT,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED
);

CREATE TABLE ski.kata_tx (
    id_tx SMALLINT PRIMARY KEY DEFAULT nextval('ski.seq_kata_id_tx'),
    from_seq SMALLINT NOT NULL ,
    to_seq SMALLINT NOT NULL ,
    tempo ski.tempo ,
    direction ski.sides ,
    intermediate_stand SMALLINT REFERENCES ski.stands(id_stand),
    notes TEXT,
    resource_url TEXT ,
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED ,
    CONSTRAINT unique_kata_tx UNIQUE (from_seq, to_seq)
);

-- Valutare come modellare il bunkai, catalogo e riferimento al kata, ma valutare le info
-- CREATE TABLE ski.bunkai_inventory(
--     bunkai_id SMALLINT PRIMARY KEY ,
--     kata_id SMALLINT NOT NULL REFERENCES ski.Kata_inventory(id_kata) ,
-- )
-- CREATE TABLE ski.kata_bunkai(
--     sequence_id SMALLINT NOT NULL REFERENCES ski.kata_sequence(id_sequence),
-- );

-- FUNZIONI AUSILIARIE PER RECUPERARE LE INFO

CREATE OR REPLACE FUNCTION ski.get_gradeid(
    _grade NUMERIC,
    _type VARCHAR
    )
    returns NUMERIC
    language sql
    as $$
        SELECT id_grade 
        FROM ski.grades 
        WHERE grade = _grade
        AND gtype = _type::ski.grade_type
        ;
    $$
;
--SELECT ski.get_gradeid(1,'dan');

CREATE OR REPLACE FUNCTION ski.get_kihons(
    _grade NUMERIC,
    _type VARCHAR
    )
    RETURNS TABLE(
        id_inventory NUMERIC ,
        grade_id NUMERIC ,
        number NUMERIC
    )
    LANGUAGE SQL
    AS $$
        SELECT id_inventory,grade_id, number FROM ski.kihon_inventory WHERE grade_id = ski.get_gradeid(_grade,_type);
    $$
;

--SELECT * FROM ski.get_kihons(1,'dan');

CREATE OR REPLACE FUNCTION ski.get_kihonid(
    _gradeid NUMERIC,
    _num NUMERIC
    )
    returns NUMERIC
    LANGUAGE SQL
    AS $$
    SELECT id_inventory FROM ski.kihon_inventory WHERE grade_id = _gradeid AND number =_num;
$$;
--SELECT ski.get_kihonid(1,'dan',1);


CREATE OR REPLACE FUNCTION ski.get_technic_info(
    _technic_id NUMERIC
    )
    RETURNS TABLE(
        id_technic SMALLINT,
        waza ski.waza_type,
        name TEXT,
        description TEXT,
        notes TEXT,
        resource_url TEXT
    )
    LANGUAGE SQL
    AS $$
        SELECT id_technic ,
            waza ,
            name ,
            description ,
            notes ,
            resource_url
        FROM ski.technics
        WHERE id_technic = _technic_id
    $$
;
-- SELECT ski.get_technic_info(12);

CREATE OR REPLACE FUNCTION ski.get_stand_info(
    _stand_id NUMERIC
    )
    RETURNS TABLE(
        id_stand SMALLINT,
        name TEXT,
        description TEXT,
        illustration_url TEXT,
        notes TEXT
    )
    LANGUAGE SQL
    AS $$
        SELECT id_stand SMALLINT,
            name TEXT,
            description TEXT,
            illustration_url TEXT,
            notes TEXT
        FROM ski.stands
        WHERE id_stand = _stand_id
    $$
;


CREATE OR REPLACE FUNCTION ski.get_strikingparts_info(
    _id_part NUMERIC
    )
    RETURNS TABLE(
        id_part SMALLINT,
        name TEXT,
        translation TEXT,
        description TEXT,
        notes TEXT,
        resource_url TEXT
    )
    LANGUAGE SQL
    AS $$
        SELECT id_part,
            name ,
            translation ,
            description ,
            notes ,
            resource_url 
        FROM ski.strikingparts
        WHERE id_part = _id_part
    $$
;

CREATE OR REPLACE FUNCTION ski.get_target_info(
    _id_target NUMERIC
    )
    RETURNS TABLE(
        id_target SMALLINT,
        name TEXT,
        original_name TEXT,
        description TEXT,
        notes TEXT,
        resource_url TEXT
    )
    LANGUAGE SQL
    AS $$
        SELECT id_target ,
            name ,
            original_name ,
            description ,
            notes ,
            resource_url 
        FROM ski.targets
        WHERE id_target = _id_target
    $$
;


CREATE OR REPLACE FUNCTION ski.get_katasequence(_kata_id NUMERIC)
    RETURNS TABLE(
        id_sequence SMALLINT ,
        kata_id SMALLINT ,
        seq_num SMALLINT ,
        stand_id SMALLINT ,
        posizione TEXT ,
        guardia ski.sides ,
        facing ski.absolute_directions ,
        Tecniche JSON ,
        embusen ski.embusen_points ,
        kiai BOOLEAN ,
        notes TEXT
    )
    language sql
    as $$
        SELECT seq.id_sequence 
            , seq.kata_id 
            , seq.seq_num 
            , seq.stand_id
            , MAX(stands.name) as posizione
            , seq.side AS guardia
            , seq.facing
            , json_agg(
                json_build_object(
                    'sequence_id' , combo.sequence_id 
                    , 'arto' , combo.arto 
                    , 'technic_id' , combo.technic_id 
                    , 'Tecnica' , combo.technic_name 
                    , 'technic_target_id' , combo.technic_target_id 
                    , 'Obiettivo' , combo.target_name 
                    , 'waza_note' , combo.waza_note
                )
            ) AS Tecniche
            , seq.embusen
            , seq.kiai
            , seq.notes
        FROM ski.kata_sequence AS seq
        JOIN (
            SELECT combo_raw.id_kswaza,
                combo_raw.sequence_id ,
                combo_raw.arto,
                combo_raw.technic_id ,
                combo_raw.technic_target_id,
                combo_raw.notes ,
                tech.name AS technic_name,
                targets.name  AS target_name,
                combo_raw.notes AS waza_note
            FROM ski.kata_sequence_waza AS combo_raw
            JOIN ski.technics AS tech
            ON combo_raw.technic_id = tech.id_technic
            LEFT JOIN ski.targets as targets
            ON combo_raw.technic_target_id = targets.id_target
        ) AS combo
        ON seq.id_sequence = combo.sequence_id
        LEFT JOIN ski.stands as stands
        ON seq.stand_id = stands.id_stand
        WHERE seq.kata_id = _kata_id
        GROUP BY seq.id_sequence
        ORDER BY seq.seq_num
        ;
    $$
;
--SELECT * FROM ski.get_katasequence(1);

CREATE OR REPLACE FUNCTION ski.get_katatx(_kata_id NUMERIC)
    RETURNS TABLE(
        id_tx SMALLINT , 
        from_seq SMALLINT ,
        to_seq SMALLINT ,
        tempo  ski.tempo ,
        direction ski.sides,
        notes TEXT
    )
    language sql
    as $$
        WITH relevantseq AS (SELECT id_sequence FROM ski.kata_sequence)
        SELECT id_tx  , 
            from_seq ,
            to_seq ,
            tempo ,
            direction,
            notes
        FROM ski.kata_tx
        WHERE from_seq IN (SELECT id_sequence FROM relevantseq)
        OR to_seq IN (SELECT id_sequence FROM relevantseq)
        ;
    $$
;
--SELECT * FROM ski.get_katatx(1);

CREATE OR REPLACE FUNCTION ski.get_ts_targets(_search TEXT)
    RETURNS TABLE(
        id SMALLINT , 
        name_rank FLOAT,
        description_rank FLOAT , 
        notes_rank FLOAT
    )
    language sql
    as $$
        WITH tsearch AS (
            SELECT id_target AS id ,
                ts_rank_cd(tsv_name, websearch_to_tsquery('simple',_search),16) AS name_rank ,    
                ts_rank_cd(tsv_description, websearch_to_tsquery('simple',_search),16) AS description_rank,
                ts_rank_cd(tsv_notes, websearch_to_tsquery('simple',_search),16) AS notes_rank
            FROM ski.targets
        )
        SELECT id ,
            name_rank ,    
            description_rank,
            notes_rank
        FROM tsearch
        WHERE name_rank >0 OR description_rank >0 OR notes_rank >0
        ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
        ;
    $$
;

CREATE OR REPLACE FUNCTION ski.get_ts_technics(_search TEXT)
    RETURNS TABLE(
        id SMALLINT , 
        name_rank FLOAT,
        description_rank FLOAT , 
        notes_rank FLOAT
    )
    language sql
    as $$
        WITH tsearch AS (
            SELECT id_technic AS id ,
                ts_rank_cd(tsv_name, websearch_to_tsquery('simple',_search),16) AS name_rank ,    
                ts_rank_cd(tsv_description, websearch_to_tsquery('simple',_search),16) AS description_rank,
                ts_rank_cd(tsv_notes, websearch_to_tsquery('simple',_search),16) AS notes_rank
            FROM ski.technics
        )
        SELECT id ,
            name_rank ,    
            description_rank,
            notes_rank
        FROM tsearch
        WHERE name_rank >0 OR description_rank >0 OR notes_rank >0
        ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
        ;
    $$
;

CREATE OR REPLACE FUNCTION ski.get_ts_stands(_search TEXT)
    RETURNS TABLE(
        id SMALLINT , 
        name_rank FLOAT,
        description_rank FLOAT , 
        notes_rank FLOAT
    )
    language sql
    as $$
        WITH tsearch AS (
            SELECT id_stand AS id ,
                ts_rank_cd(tsv_name, websearch_to_tsquery('simple',_search),16) AS name_rank ,    
                ts_rank_cd(tsv_description, websearch_to_tsquery('simple',_search),16) AS description_rank,
                ts_rank_cd(tsv_notes, websearch_to_tsquery('simple',_search),16) AS notes_rank
            FROM ski.stands
        )
        SELECT id ,
            name_rank ,    
            description_rank,
            notes_rank
        FROM tsearch
        WHERE name_rank >0 OR description_rank >0 OR notes_rank >0
        ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
        ;
    $$
;

CREATE OR REPLACE FUNCTION ski.get_ts_strikingparts(_search TEXT)
    RETURNS TABLE(
        id SMALLINT , 
        name_rank FLOAT,
        description_rank FLOAT , 
        notes_rank FLOAT
    )
    language sql
    as $$
        WITH tsearch AS (
            SELECT id_part AS id ,
                ts_rank_cd(tsv_name, websearch_to_tsquery('simple',_search),16) AS name_rank ,    
                ts_rank_cd(tsv_description, websearch_to_tsquery('simple',_search),16) AS description_rank,
                ts_rank_cd(tsv_notes, websearch_to_tsquery('simple',_search),16) AS notes_rank
            FROM ski.strikingparts
        )
        SELECT id ,
            name_rank ,    
            description_rank,
            notes_rank
        FROM tsearch
        WHERE name_rank >0 OR description_rank >0 OR notes_rank >0
        ORDER BY name_rank DESC, description_rank DESC, notes_rank DESC;
        ;
    $$
;

CREATE OR REPLACE FUNCTION ski.ts_normalizer(
    _name_rank FLOAT ,
    _description_rank FLOAT ,
    _notes_rank FLOAT ,
    _name_wht FLOAT DEFAULT 1.0,
    _description_wht FLOAT DEFAULT 0.75,
    _notes_wht FLOAT DEFAULT 0.25
    )
    RETURNS FLOAT
    LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $funzione$
        SELECT  coalesce(_name_rank, 0)*_name_wht + coalesce(_description_rank, 0)*_description_wht + coalesce(_notes_rank, 0)*_notes_wht;
    $funzione$
;



DROP SCHEMA staging CASCADE;
DROP SCHEMA upsert CASCADE;
DROP SCHEMA reject CASCADE;

CREATE SCHEMA staging;
CREATE SCHEMA upsert;
CREATE SCHEMA reject;

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
  CONSTRAINT unique_targetname UNIQUE(name)
); -- parti del corpo colpite

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
  CONSTRAINT unique_strikingpartsname UNIQUE(name)
); -- parti del corpo che colpiscono

CREATE TABLE staging.technics(
  id_technic SMALLINT UNIQUE,
  waza ski.waza_type,
  name VARCHAR(255) NOT NULL,
  -- aka VARCHAR(255) ,
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_technicname UNIQUE(name)
); --Inventario delle tecniche

CREATE TABLE staging.stands(
  id_stand SMALLINT UNIQUE,
  name VARCHAR(255) NOT NULL,
  -- aka VARCHAR(255) , -- altoro nome con la quale è conosciuta
  description TEXT,
  illustration_url TEXT,
  notes TEXT,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_standname UNIQUE(name)
); --Inventario delle posizioni

CREATE TABLE staging.grades(
  id_grade SMALLINT UNIQUE,
  gtype ski.grade_type NOT NULL,
  grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
  color ski.beltcolor,
  staging_autoid BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_grade UNIQUE (gtype, grade)
); -- forma normale della sequenza di gradi Kiu e Dan

CREATE TABLE staging.kihon_inventory(
  id_inventory SMALLINT ,
  grade_id SMALLINT NOT NULL, -- REFERENCES ski.grades(id_grade) 
  number SMALLINT NOT NULL,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL ,
  CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
);

CREATE TABLE staging.kihon_sequences(
  id_sequence SMALLINT UNIQUE ,
  inventory_id SMALLINT NOT NULL, -- REFERENCES ski.kihon_inventory(id_inventory)
  seq_num SMALLINT NOT NULL, 
  stand SMALLINT NOT NULL , -- REFERENCES ski.stands(id_stand)
  techinc SMALLINT NOT NULL , -- REFERENCES ski.technics(id_technic)
  gyaku bool DEFAULT 'false',
  target_hgt ski.target_hgt ,
  notes TEXT ,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_kihonsequence UNIQUE (inventory_id, seq_num)
);

CREATE TABLE staging.kihon_tx(
  id_tx SMALLINT UNIQUE ,
  from_seq SMALLINT NOT NULL , -- REFERENCES ski.kihon_sequences(id_sequence)
  to_seq SMALLINT NOT NULL , -- REFERENCES ski.kihon_sequences(id_sequence)
  movement ski.movements ,
  notes TEXT,
  tempo ski.tempo ,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
); 

CREATE TABLE staging.Kata_inventory(
  id_kata SMALLINT UNIQUE,
  kata VARCHAR(255) NOT NULL,
  serie ski.kata_series,
  starting_leg ski.sides NOT NULL,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_kata UNIQUE (kata)
);

CREATE TABLE staging.kata_sequence(
  id_sequence SMALLINT UNIQUE ,
  kata_id SMALLINT NOT NULL , -- REFERENCES ski.Kata_inventory(id_kata)
  seq_num SMALLINT NOT NULL,
  stand_id SMALLINT NOT NULL , -- REFERENCES ski.stands(id_stand)
  speed ski.tempo ,
  side ski.sides, 
  embusen ski.embusen_points ,
  facing ski.absolute_directions, 
  kiai bool,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  CONSTRAINT unique_kata_seq UNIQUE (kata_id, seq_num)
); 

CREATE TABLE staging.kata_sequence_waza (
  id_kswaza SMALLINT UNIQUE ,
  sequence_id SMALLINT , --REFERENCES ski.kata_sequence(id_sequence)
  arto ski.arti,
  technic_id SMALLINT NOT NULL , -- REFERENCES ski.technics(id_technic)
  strikingpart_id SMALLINT , -- REFERENCES ski.strikingparts(id_part)
  technic_target_id SMALLINT , -- REFERENCES ski.targets(id_target)
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL
);

CREATE TABLE staging.kata_tx (
  id_tx SMALLINT UNIQUE ,
  from_seq SMALLINT NOT NULL ,
  to_seq SMALLINT NOT NULL ,
  tempo ski.tempo ,
  direction ski.sides ,
  intermediate_stand SMALLINT , -- 
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL
);


CREATE VIEW staging.dom_targets AS
  SELECT id_target FROM ski.targets
  UNION
  SELECT id_target FROM staging.targets
;

CREATE VIEW staging.dom_strikingparts AS
  SELECT id_part FROM ski.strikingparts
  UNION
  SELECT id_part FROM staging.strikingparts
;

CREATE VIEW staging.dom_technics AS
  SELECT id_technic FROM ski.technics
  UNION
  SELECT id_technic FROM staging.technics
;

CREATE VIEW staging.dom_stands AS
  SELECT id_stand FROM ski.stands
  UNION
  SELECT id_stand FROM staging.stands
;

CREATE VIEW staging.dom_grades AS
  SELECT id_grade FROM ski.grades
  UNION
  SELECT id_grade FROM staging.grades
;

CREATE VIEW staging.dom_kihon_inventory AS
  SELECT id_inventory FROM ski.kihon_inventory
  UNION
  SELECT id_inventory FROM staging.kihon_inventory
;

CREATE VIEW staging.dom_kihon_sequences AS
  SELECT id_sequence FROM ski.kihon_sequences
  UNION
  SELECT id_sequence FROM staging.kihon_sequences
;

CREATE VIEW staging.dom_kihon_tx AS
  SELECT id_tx FROM ski.kihon_tx
  UNION
  SELECT id_tx FROM staging.kihon_tx
;

CREATE VIEW staging.dom_kata_inventory AS
  SELECT id_kata FROM ski.Kata_inventory
  UNION
  SELECT id_kata FROM staging.Kata_inventory
;

CREATE VIEW staging.dom_kata_sequence AS
  SELECT id_sequence FROM ski.kata_sequence
  UNION
  SELECT id_sequence FROM staging.kata_sequence
;

CREATE VIEW staging.dom_kata_sequence_waza AS
  SELECT id_kswaza FROM ski.kata_sequence_waza
  UNION
  SELECT id_kswaza FROM staging.kata_sequence_waza
;

CREATE VIEW staging.dom_kata_tx AS
  SELECT id_tx FROM ski.kata_tx
  UNION
  SELECT id_tx FROM staging.kata_tx
;

-- upsert tables
CREATE TABLE upsert.technics(
  id_technic SMALLINT ,
  waza ski.waza_type,
  name VARCHAR(255) ,
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
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
  gtype ski.grade_type,
  grade SMALLINT,
  color ski.beltcolor,
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
  stand SMALLINT,
  techinc SMALLINT,
  gyaku bool,
  target_hgt ski.target_hgt,
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
  from_seq SMALLINT,
  to_seq SMALLINT,
  movement ski.movements,
  notes TEXT,
  tempo ski.tempo,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.Kata_inventory(
  id_kata SMALLINT,
  kata VARCHAR(255),
  serie ski.kata_series,
  starting_leg ski.sides,
  notes TEXT,
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
  speed ski.tempo,
  side ski.sides,
  embusen ski.embusen_points,
  facing ski.absolute_directions,
  kiai bool,
  notes TEXT,
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
  arto ski.arti,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE upsert.kata_tx(
  id_tx SMALLINT,
  from_seq SMALLINT,
  to_seq SMALLINT,
  tempo ski.tempo,
  direction ski.sides,
  intermediate_stand SMALLINT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

-- rejected tables
CREATE TABLE reject.technics(
  id_technic SMALLINT ,
  waza ski.waza_type,
  name VARCHAR(255) ,
  description TEXT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
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
  gtype ski.grade_type,
  grade SMALLINT,
  color ski.beltcolor,
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
  stand SMALLINT,
  techinc SMALLINT,
  gyaku bool,
  target_hgt ski.target_hgt,
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
  from_seq SMALLINT,
  to_seq SMALLINT,
  movement ski.movements,
  notes TEXT,
  tempo ski.tempo,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.Kata_inventory(
  id_kata SMALLINT,
  kata VARCHAR(255),
  serie ski.kata_series,
  starting_leg ski.sides,
  notes TEXT,
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
  speed ski.tempo,
  side ski.sides,
  embusen ski.embusen_points,
  facing ski.absolute_directions,
  kiai bool,
  notes TEXT,
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
  arto ski.arti,
  technic_id SMALLINT,
  strikingpart_id SMALLINT,
  technic_target_id SMALLINT,
  notes TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

CREATE TABLE reject.kata_tx(
  id_tx SMALLINT,
  from_seq SMALLINT,
  to_seq SMALLINT,
  tempo ski.tempo,
  direction ski.sides,
  intermediate_stand SMALLINT,
  notes TEXT,
  resource_url TEXT,
  staging_autoid BOOL,
  staging_fk_error BOOL,
  staging_pk_update BOOL,
  staging_update BOOL,
  insertion TIMESTAMP
);

--
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_technics()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS $$
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
  $$
;

-- Targets
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_targets()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Strikingparts
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_strikingparts()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Stands
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_stands()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Grades
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_grades()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Kihon Inventory
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_inventory()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_inventory ', MAX(id_inventory), true) FROM staging.dom_kihon_inventory;
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
  $$
;

-- Kihon Sequences
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_sequences()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_sequence', MAX(id_sequence), true) FROM staging.dom_kihon_sequences;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kihon_sequences SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_sequence, l.inventory_id, l.seq_num, l.stand, l.techinc, l.gyaku, l.target_hgt, l.notes
    FROM staging.kihon_sequences l
    INNER JOIN ski.kihon_sequences r ON l.id_sequence = r.id_sequence
    ),
    tbl_pk_update AS (
      UPDATE ski.kihon_sequences t
      SET inventory_id = dupkey.inventory_id,
        seq_num = dupkey.seq_num,
        stand = dupkey.stand,
        techinc = dupkey.techinc,
        gyaku = dupkey.gyaku,
        target_hgt = dupkey.target_hgt,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_sequence = dupkey.id_sequence
      RETURNING t.id_sequence
    ),
    tbl_update AS (
      INSERT INTO ski.kihon_sequences(
        id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes
      )
      SELECT id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes
      FROM (
        SELECT tot.id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes
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
      id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_sequences
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kihon_sequences (
      id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_sequence, inventory_id, seq_num, stand, techinc, gyaku, target_hgt, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_sequences
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kihon_sequences;

    RETURN NULL;
  END;
  $$
;

-- Kihon TX
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kihon_tx()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kihon_id_tx', MAX(id_tx), true) FROM staging.dom_kihon_tx;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.kihon_tx SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_tx, l.from_seq, l.to_seq, l.movement, l.notes, l.tempo
    FROM staging.kihon_tx l
    INNER JOIN ski.kihon_tx r ON l.id_tx = r.id_tx
    ),
    tbl_pk_update AS (
      UPDATE ski.kihon_tx t
      SET from_seq = dupkey.from_seq,
        to_seq = dupkey.to_seq,
        movement = dupkey.movement,
        notes = dupkey.notes,
        tempo = dupkey.tempo
      FROM dupkey
      WHERE t.id_tx = dupkey.id_tx
      RETURNING t.id_tx
    ),
    tbl_update AS (
      INSERT INTO ski.kihon_tx(
        id_tx, from_seq, to_seq, movement, notes, tempo
      )
      SELECT id_tx, from_seq, to_seq, movement, notes, tempo
      FROM (
        SELECT tot.id_tx, from_seq, to_seq, movement, notes, tempo
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
      id_tx, from_seq, to_seq, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_seq, to_seq, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_tx
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kihon_tx (
      id_tx, from_seq, to_seq, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_seq, to_seq, movement, notes, tempo,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kihon_tx
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kihon_tx;

    RETURN NULL;
  END;
  $$
;

-- Kata Inventory
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_inventory()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
  DECLARE
  seq_adj integer;
  tms_op timestamp;
  BEGIN
  SELECT INTO seq_adj setval('ski.seq_kata_id_kata', MAX(id_kata), true) FROM staging.dom_kata_inventory;
  SELECT INTO tms_op CURRENT_TIMESTAMP;
    UPDATE staging.Kata_inventory SET staging_autoid = false WHERE staging_autoid IS NULL;
    WITH
    dupkey AS (
    SELECT l.id_kata, l.kata, l.serie, l.starting_leg, l.notes
    FROM staging.Kata_inventory l
    INNER JOIN ski.Kata_inventory r ON l.id_kata = r.id_kata
    ),
    tbl_pk_update AS (
      UPDATE ski.Kata_inventory t
      SET kata = dupkey.kata,
        serie = dupkey.serie,
        starting_leg = dupkey.starting_leg,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_kata = dupkey.id_kata
      RETURNING t.id_kata
    ),
    tbl_update AS (
      INSERT INTO ski.Kata_inventory(
        id_kata, kata, serie, starting_leg, notes
      )
      SELECT id_kata, kata, serie, starting_leg, notes
      FROM (
        SELECT tot.id_kata, kata, serie, starting_leg, notes
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
        notes = EXCLUDED.notes
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

    INSERT INTO upsert.Kata_inventory (
      id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.Kata_inventory
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.Kata_inventory (
      id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_kata, kata, serie, starting_leg, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.Kata_inventory
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.Kata_inventory;

    RETURN NULL;
  END;
  $$
;

-- Kata Sequences
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_sequences()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Kata Sequence Waza
-- pq: WITH query "tbl_update" does not have a RETURNING clause 
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_sequence_waza()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
  $$
;

-- Kata TX
CREATE OR REPLACE FUNCTION staging.trigfunc_ins_kata_tx()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL VOLATILE
  AS
  $$
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
    SELECT l.id_tx, l.from_seq, l.to_seq, l.tempo, l.direction, l.intermediate_stand, l.notes
    FROM staging.kata_tx l
    INNER JOIN ski.kata_tx r ON l.id_tx = r.id_tx
    ),
    tbl_pk_update AS (
      UPDATE ski.kata_tx t
      SET from_seq = dupkey.from_seq,
        to_seq = dupkey.to_seq,
        tempo = dupkey.tempo,
        direction = dupkey.direction,
        intermediate_stand = dupkey.intermediate_stand,
        notes = dupkey.notes
      FROM dupkey
      WHERE t.id_tx = dupkey.id_tx
      RETURNING t.id_tx
    ),
    tbl_update AS (
      INSERT INTO ski.kata_tx(
        id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes
      )
      SELECT id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes
      FROM (
        SELECT tot.id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes
        FROM staging.kata_tx tot
        LEFT JOIN tbl_pk_update esc ON tot.id_tx = esc.id_tx
        WHERE esc.id_tx IS NULL
      )
      ON CONFLICT ON CONSTRAINT unique_kata_tx
      DO UPDATE SET
        id_tx = EXCLUDED.id_tx,
        from_seq = EXCLUDED.from_seq,
        to_seq = EXCLUDED.to_seq,
        tempo = EXCLUDED.tempo,
        direction = EXCLUDED.direction,
        intermediate_stand = EXCLUDED.intermediate_stand,
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
      id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_tx
    WHERE staging_pk_update = true OR staging_update = true;

    INSERT INTO reject.kata_tx (
      id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes,
      staging_autoid, staging_pk_update, staging_update, insertion
    )
    SELECT id_tx, from_seq, to_seq, tempo, direction, intermediate_stand, notes,
      staging_autoid, staging_pk_update, staging_update, tms_op
    FROM staging.kata_tx
    WHERE NOT (staging_pk_update = true OR staging_update = true);

    DELETE FROM staging.kata_tx;

    RETURN NULL;
  END;
  $$
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
  ON staging.Kata_inventory
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