-- Draft DB schema for the emb0x project. 
-- One has to get this right from the very start otherwise bad things can happen.
-- No financial data in here at least though

CREATE TABLE user (
    id NOT NULL INT PRIMARY KEY AUTO_INCREMENT,
    name NOT NULL VARCHAR(255) NOT NULL,
    email NOT NULL VARCHAR(255) NOT NULL,
    password_hash NOT NULL VARCHAR(255) NOT NULL,
    salt NOT NULL VARCHAR(255) NOT NULL,
    access ENUM('fan', 'stakeholder', 'caretaker') NOT NULL,
    created_on NOT NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE track (
    id NOT NULL INT PRIMARY KEY AUTO_INCREMENT,
    name NOT NULL VARCHAR(255) NOT NULL,
    artist NOT NULL VARCHAR(255) NOT NULL,
    track_num NULL INT,
    genre NOT NULL VARCHAR(255) NOT NULL, -- FK to Genre table
    description NOT NULL TEXT,
    created_on NOT NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE track_artist (
    track_id NOT NULL INT,
    artist_id NOT NULL INT,
    PRIMARY KEY (artist_id, track_id)
);

-- A release is a collection of tracks presented as a group (e.g. an album)
CREATE TABLE release (
    id NOT NULL INT PRIMARY KEY AUTO_INCREMENT,
    name NOT NULL VARCHAR(255) NOT NULL,
    type ENUM('album', 'single', 'ep', 'compilation') NOT NULL,
    release_date NOT NULL DATE,
    description NOT NULL TEXT,
    created_on NOT NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on NULL TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE release_track (
    release_id NOT NULL INT,
    track_id NOT NULL INT,
    order_num NOT NULL INT,
    disc_num NULL INT,
    PRIMARY KEY (release_id, track_id)
)

-- Release artists are the artists that are credited on the release but not 
-- necessarily on the tracks contained within the release
CREATE TABLE release_artist (
    release_id NOT NULL INT,
    artist_id NOT NULL INT,
    PRIMARY KEY (release_id, artist_id)
);

