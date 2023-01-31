CREATE USER arcsrc PASSWORD 'password';
ALTER USER arcsrc CREATEDB;
ALTER ROLE arcsrc WITH REPLICATION;
CREATE DATABASE arcsrc WITH OWNER arcsrc ENCODING 'UTF8';
CREATE DATABASE io WITH OWNER arcsrc ENCODING 'UTF8';

SELECT 'init' FROM pg_create_logical_replication_slot('test_decoding', 'test_decoding');
SELECT 'init' FROM pg_create_logical_replication_slot('wal2json', 'wal2json');
SELECT * from pg_replication_slots;
