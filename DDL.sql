CREATE SCHEMA ski;

CREATE TYPE ski.grade_type AS ENUM ('kyu','dan');
CREATE TYPE ski.sides AS ENUM ('sx','frontal','dx');
CREATE TYPE ski.movements AS ENUM('Fwd','Still','Bkw');
CREATE TYPE ski.kata_series AS ENUM ('Heian','Tekki','Sentei');
CREATE TYPE ski.target AS ENUM('Jodan','Chudan','Gedan');
CREATE TYPE ski.waza_type AS ENUM('Uke','Uchi','Geri','NA','_');
CREATE TYPE ski.embusen_points AS (
    x SMALLINT,
    y SMALLINT
);
CREATE TYPE ski.arti AS ENUM('Braccio DX','Braccio SX','Braccia','Gamba DX','Gamba SX','Gambe');


CREATE TABLE ski.technics(
    id_technic SMALLSERIAL PRIMARY KEY,
    waza ski.waza_type,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) ,
    description TEXT,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_technicname UNIQUE(name)
);

-- tabella spostamenti

CREATE TABLE ski.stands(
    id_stand SMALLSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    -- aka VARCHAR(255) ,
    description TEXT,
    illustration_url TEXT,
    notes TEXT
);

CREATE TABLE ski.grades(
    id_grade SMALLSERIAL PRIMARY KEY,
    gtype ski.grade_type NOT NULL,
    grade SMALLINT CHECK (grade BETWEEN 1 AND 10) NOT NULL ,
    CONSTRAINT unique_grade UNIQUE (gtype, grade)
);

CREATE TABLE ski.kihon_inventory(
    id_inventory SMALLSERIAL PRIMARY KEY,
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
);

CREATE TABLE ski.kihon_sequences(
    id_sequence SMALLSERIAL PRIMARY KEY,
    inventory_id SMALLSERIAL NOT NULL REFERENCES ski.kihon_inventory(id_inventory),
    seq_num SMALLINT NOT NULL,
    stand SMALLSERIAL NOT NULL REFERENCES ski.stands(id_stand),
    techinc SMALLSERIAL NOT NULL REFERENCES ski.technics(id_technic),
    gyaku bool,
    target_hgt VARCHAR(255) ,
    note TEXT ,
    resource_url TEXT,
    CONSTRAINT unique_kihonsequence UNIQUE (inventory_id, seq_num)
);

CREATE TABLE ski.kihon_tx(
    id_tx SMALLSERIAL PRIMARY KEY,
    from_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    to_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    --direction ski.sides ,
    --rotation SMALLINT ,
    movement ski.movements ,
    note TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
);

CREATE TABLE ski.Kata_inventory(
    id_kata SMALLSERIAL PRIMARY KEY,
    kata VARCHAR(255) NOT NULL,
    serie ski.kata_series,
    starting_leg ski.sides NOT NULL,
    Note TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata UNIQUE (kata)
);

CREATE TABLE ski.kata_sequence(
    id_sequence SMALLSERIAL PRIMARY KEY,
    kata_id SMALLSERIAL NOT NULL,
    seq_num SMALLSERIAL NOT NULL,
    stand SMALLSERIAL NOT NULL REFERENCES ski.stands(id_stand),
    --technic SMALLSERIAL NOT NULL REFERENCES ski.technics(id_technic),
    --technic_target SMALLSERIAL NOT NULL,
    --embusen
    --facing
    notes TEXT,
    resource_url TEXT, 
    CONSTRAINT unique_kata_seq UNIQUE (kata_id, seq_num)
);

CREATE TABLE ski.kata_tx(
    id_tx SMALLSERIAL PRIMARY KEY ,
    from_seq SMALLINT NOT NULL ,
    to_seq SMALLINT NOT NULL ,
    direction ski.sides ,
    --rotation SMALLINT ,
    movement ski.movements ,
    intermediate_stand SMALLSERIAL REFERENCES ski.stands(id_stand),
    note TEXT,
    resource_url TEXT 
);


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

CREATE TABLE ski.combotecniche_kata (
    id SMALLINT REFERENCES ski.kata_sequence(id_sequence),
    arto ski.arti,
    technic SMALLSERIAL NOT NULL REFERENCES ski.technics(id_technic),
    technic_target SMALLSERIAL NOT NULL
);
