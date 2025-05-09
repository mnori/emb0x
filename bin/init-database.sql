DROP TABLE IF EXISTS track_artist;
DROP TABLE IF EXISTS tracklist_track;
DROP TABLE IF EXISTS track;
DROP TABLE IF EXISTS tracklist;
DROP TABLE IF EXISTS tracklist_artist;
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    access ENUM('fan', 'stakeholder', 'caretaker') DEFAULT 'fan',
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    removed_reason TEXT NOT NULL,
    PRIMARY KEY (id),
);

CREATE TABLE track (
    id INT NOT NULL AUTO_INCREMENT,
    track_name VARCHAR(255) NULL,
    artist_name VARCHAR(255) NULL, -- for when the artist is yet to be a user
    artist_user_id INT NULL, -- FK to User table
    track_description TEXT NULL,
    genre VARCHAR(255) NULL, -- FK to Genre table
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    removed_reason TEXT NOT NULL,
    FOREIGN KEY (artist_user_id) REFERENCES user(id),
    PRIMARY KEY (id)
);

CREATE TABLE track_artist (
    track_id INT NOT NULL,
    artist_id INT NOT NULL,
    PRIMARY KEY (artist_id, track_id),
    FOREIGN KEY (track_id) REFERENCES track(id),
    FOREIGN KEY (artist_id) REFERENCES user(id)
);

-- A collection of tracks presented as a group (e.g. an album)
CREATE TABLE tracklist (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    type ENUM('album', 'single', 'ep', 'compilation') NOT NULL,
    released_on DATE NOT NULL,
    description TEXT NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tracklist_track (
    tracklist_id INT NOT NULL,
    track_id INT NOT NULL,
    order_num INT NOT NULL,
    disc_num INT NULL,
    PRIMARY KEY (tracklist_id, track_id),
    FOREIGN KEY (tracklist_id) REFERENCES tracklist(id),
    FOREIGN KEY (track_id) REFERENCES track(id)
);

-- Tracklist (e.g. album) artists are the artists that are credited on the tracklist (e.g. album) but not 
-- necessarily on the tracks contained within the tracklist
CREATE TABLE tracklist_artist (
    tracklist_id INT NOT NULL,
    artist_id INT NOT NULL,
    PRIMARY KEY (tracklist_id, artist_id),
    FOREIGN KEY (tracklist_id) REFERENCES tracklist(id),
    FOREIGN KEY (artist_id) REFERENCES user(id)
);

