#!/bin/bash

# Variables
CONTAINER_NAME="mysql"
DB_USER="the-caretaker"
DB_PASSWORD="confidentcats4eva"
DB_NAME="emb0x"
SQL_FILE="init-database.sql"

# Execute the SQL file inside the MySQL container
docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME < $SQL_FILE

echo "Reached the end of initialising the database"