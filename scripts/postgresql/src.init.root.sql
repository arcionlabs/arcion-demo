CREATE USER ${SRCDB_ARC_USER} PASSWORD '${SRCDB_ARC_PW}';
ALTER USER ${SRCDB_ARC_USER} CREATEDB;
ALTER ROLE ${SRCDB_ARC_USER} WITH REPLICATION;
CREATE DATABASE ${SRCDB_DB} WITH OWNER ${SRCDB_ARC_USER} ENCODING 'UTF8';

