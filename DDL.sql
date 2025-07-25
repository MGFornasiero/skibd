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
-- In alternativa servirebbe un tipo array ma non sarebbero disponibili i constraint, quindi punta alla tabella collegata e 

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
    tsv_notes tsvector GENERATED ALWAYS AS (to_tsvector('simple',notes)) STORED
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