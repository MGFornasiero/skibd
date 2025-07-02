CREATE SCHEMA ski;

CREATE TYPE ski.grade_type AS ENUM ('kyu','dan');
CREATE TYPE ski.sides AS ENUM ('sx','frontal','dx');
CREATE TYPE ski.movements AS ENUM('Fwd','Still','Bkw');
CREATE TYPE ski.kata_series AS ENUM ('Heian','Tekki','Sentei');
CREATE TYPE ski.target_hgt AS ENUM('Jodan','Chudan','Gedan');
CREATE TYPE ski.waza_type AS ENUM('Uke','Uchi','Geri','NA','_');
CREATE TYPE ski.tempo AS ENUM('Legato','Fast','Normal','Slow','Breath');

CREATE TYPE ski.embusen_points AS (
    x SMALLINT,
    y SMALLINT
); -- Definisce la posizione nello spazio come piano cartesiano con 0 in posizione del saluto

CREATE TYPE ski.arti AS ENUM('Braccio DX','Braccio SX','Braccia','Gamba DX','Gamba SX','Gambe','NA');

CREATE TYPE ski.absolute_directions AS ENUM(
    'N',
    'NE',
    'E',
    'SE'
    'S',
    'SO'
    'O',
    'NO'
); -- Direzione assoluta rispetto al saluto inizale

CREATE TABLE ski.targets(
    id_target SMALLSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255)
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_technicname UNIQUE(name)
); -- parti del corpo colpite

CREATE TABLE ski.strikingparts(
    id_target SMALLSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    translation VARCHAR(255)
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_technicname UNIQUE(name)
); -- parti del corpo che colpiscono

CREATE TABLE ski.technics(
    id_technic SMALLSERIAL PRIMARY KEY,
    waza ski.waza_type,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) ,
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_technicname UNIQUE(name)
); --Inventario delle tecniche

CREATE TABLE ski.stands(
    id_stand SMALLSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) , -- altoro nome con la quale è conosciuta
    description TEXT,
    illustration_url TEXT,
    notes TEXT
); --Inventario delle posizioni

CREATE TABLE ski.grades(
    id_grade SMALLSERIAL PRIMARY KEY,
    gtype ski.grade_type NOT NULL,
    grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
    CONSTRAINT unique_grade UNIQUE (gtype, grade)
); -- forma normale della sequenza di gradi Kiu e Dan

CREATE TABLE ski.kihon_inventory(
    id_inventory SMALLSERIAL PRIMARY KEY,
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
); -- Inventario in forma normale con i kihon per ciascuna cintura

CREATE TABLE ski.kihon_sequences(
    id_sequence SMALLSERIAL PRIMARY KEY,
    inventory_id SMALLSERIAL NOT NULL REFERENCES ski.kihon_inventory(id_inventory),
    seq_num SMALLINT NOT NULL, -- Posizione ordinale nella sequenza
    stand SMALLSERIAL NOT NULL REFERENCES ski.stands(id_stand),
    techinc SMALLSERIAL NOT NULL REFERENCES ski.technics(id_technic),
    gyaku bool,
    target_hgt ski.target_hgt ,
    note TEXT ,
    resource_url TEXT,
    CONSTRAINT unique_kihonsequence UNIQUE (inventory_id, seq_num)
); --Sequenza delle tecniche che compongono i kihon

CREATE TABLE ski.kihon_tx(
    id_tx SMALLSERIAL PRIMARY KEY,
    from_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence), 
    to_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    movement ski.movements ,
    note TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
); --Passaggio da una tecnica all' altra 

CREATE TABLE ski.Kata_inventory(
    id_kata SMALLSERIAL PRIMARY KEY,
    kata VARCHAR(255) NOT NULL,
    serie ski.kata_series,
    starting_leg ski.sides NOT NULL,
    Note TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata UNIQUE (kata)
); -- Inventario in forma normale dei kata

CREATE TABLE ski.kata_sequence(
    id_sequence SMALLSERIAL PRIMARY KEY,
    kata_id SMALLSERIAL NOT NULL REFERENCES ski.Kata_inventory(id_kata),
    seq_num SMALLSERIAL NOT NULL,
    stand SMALLSERIAL NOT NULL REFERENCES ski.stands(id_stand),
    side ski.sides,
    embusen ski.embusen_points ,
    facing ski.absolute_directions,
    kiai bool,
    notes TEXT,
    resource_url TEXT, 
    CONSTRAINT unique_kata_seq UNIQUE (kata_id, seq_num)
); -- Sequenza in forma normale del kata
--le tecniche da eseguire sono nella tabella ski.kata_sequence_waza per rispettare forma normale potendo essercene più d'una.
-- In alternativa servirebbe un tipo array ma non sarebbero disponibili i constraint, quindi punta alla tabella collegata e 

CREATE TABLE ski.kata_sequence_waza (
    id_kswaza SMALLSERIAL PRIMARY KEY 
    sequence_id SMALLINT REFERENCES ski.kata_sequence(id_sequence),
    arto ski.arti,
    technic_id SMALLSERIAL NOT NULL REFERENCES ski.technics(id_technic),
    technic_target_id SMALLSERIAL REFERENCES ski.targets(id_target),
    notes TEXT
);

CREATE TABLE ski.kata_tx(
    id_tx SMALLSERIAL PRIMARY KEY ,
    from_seq SMALLINT NOT NULL ,
    to_seq SMALLINT NOT NULL ,
    tempo ski.tempo ,
    direction ski.sides ,
    intermediate_stand SMALLSERIAL REFERENCES ski.stands(id_stand),
    note TEXT,
    resource_url TEXT 
);



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
$$;
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
$$;

--SELECT * FROM ski.get_kihon(1,'dan');

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

CREATE OR REPLACE FUNCTION ski.get_technic_name(
_technic_id NUMERIC
)
returns VARCHAR
LANGUAGE SQL
AS $$
SELECT name FROM ski.technics WHERE id_technic = _technic_id;
$$;
--Per mettere il nome della tecnica nell' output;

CREATE OR REPLACE FUNCTION ski.get_stand_name(
_stand_id NUMERIC
)
returns VARCHAR
LANGUAGE SQL
AS $$
SELECT name FROM ski.stands WHERE id_stand = _stand_id;
$$;
--Per mettere il nome della posizione nell' output;


