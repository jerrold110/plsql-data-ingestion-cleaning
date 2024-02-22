#!/bin/bash

DB_USER="user_1"
DB_PASSWORD="user_1"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="alpha"

# Create tables
echo 'Creating tables.'
CREATE_TABLE_SCRIPT="create_tables.sql"
PSQL_COMMAND="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -W -f $CREATE_TABLE_SCRIPT"
$PSQL_COMMAND

# Load data into staging
echo 'Loading staging.'
STAGE_SCRIPT="load_stage.sql"
STAGE_COMMAND="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -W -f $STAGE_SCRIPT"
$STAGE_COMMAND

# Load data from staging into tables
echo 'Loading tables from staging.'
LOAD_SCRIPT="load_main.sql"
LOAD_COMMAND="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -W -f $LOAD_SCRIPT"
$LOAD_COMMAND


