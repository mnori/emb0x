DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS track;
DROP TABLE IF EXISTS track_artist;
DROP TABLE IF EXISTS `release`;
DROP TABLE IF EXISTS release_track;
DROP TABLE IF EXISTS release_artist;

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
    PRIMARY KEY (id)
);

CREATE TABLE track (
    id INT NOT NULL AUTO_INCREMENT,
    track_name VARCHAR(255) NULL,
    artist_name VARCHAR(255) NULL,
    artist_user_id INT NULL, -- FK to User table
    track_description TEXT NULL,
    genre VARCHAR(255) NULL, -- FK to Genre table
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE TABLE track_artist (
    track_id INT NOT NULL,
    artist_id INT NOT NULL,
    PRIMARY KEY (artist_id, track_id)
);

-- A release is a collection of tracks presented as a group (e.g. an album)
CREATE TABLE `release` (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    type ENUM('album', 'single', 'ep', 'compilation') NOT NULL,
    released_on DATE NOT NULL,
    description TEXT NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    removed_on TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE release_track (
    release_id INT NOT NULL,
    track_id INT NOT NULL,
    order_num INT NOT NULL,
    disc_num INT NULL,
    PRIMARY KEY (release_id, track_id)
);

-- Release artists are the artists that are credited on the release but not 
-- necessarily on the tracks contained within the release
CREATE TABLE release_artist (
    release_id INT NOT NULL,
    artist_id INT NOT NULL,
    PRIMARY KEY (release_id, artist_id)
);

