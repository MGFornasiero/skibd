CREATE SCHEMA staging;

CREATE TABLE staging.kihon_inventory(
    id_inventory SMALLINT,
    grade_id SMALLINT NOT NULL REFERENCES ski.grades(id_grade),
    number SMALLINT NOT NULL,
    notes TEXT,
    CONSTRAINT unique_kihoninventory UNIQUE (grade_id, number)
);

CREATE TABLE staging.kihon_sequences(
    id_sequence SMALLINT PRIMARY KEY,
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
    id_tx SMALLINT PRIMARY KEY,
    from_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence), 
    to_seq SMALLINT NOT NULL REFERENCES ski.kihon_sequences(id_sequence),
    movement ski.movements ,
    notes TEXT,
    tempo ski.tempo ,
    resource_url TEXT,
    CONSTRAINT unique_kihontx UNIQUE (from_seq, to_seq)
); 

CREATE TABLE staging.Kata_inventory(
    id_kata SMALLINT PRIMARY KEY,
    kata VARCHAR(255) NOT NULL,
    serie ski.kata_series,
    starting_leg ski.sides NOT NULL,
    notes TEXT,
    resource_url TEXT,
    CONSTRAINT unique_kata UNIQUE (kata)
);

CREATE TABLE staging.kata_sequence(
    id_sequence SMALLINT PRIMARY KEY,
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
    id_kswaza SMALLINT PRIMARY KEY,
    sequence_id SMALLINT REFERENCES ski.kata_sequence(id_sequence),
    arto ski.arti,
    technic_id SMALLINT NOT NULL REFERENCES ski.technics(id_technic),
    strikingpart_id SMALLINT REFERENCES ski.strikingparts(id_part),
    technic_target_id SMALLINT REFERENCES ski.targets(id_target),
    notes TEXT
);

CREATE TABLE staging.kata_tx (
    id_tx SMALLINT PRIMARY KEY ,
    from_seq SMALLINT NOT NULL ,
    to_seq SMALLINT NOT NULL ,
    tempo ski.tempo ,
    direction ski.sides ,
    intermediate_stand SMALLINT REFERENCES ski.stands(id_stand),
    notes TEXT,
    resource_url TEXT
);




