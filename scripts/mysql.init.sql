-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';


-- create ycsb user account
CREATE USER IF NOT EXISTS 'ycsb'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'ycsb'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON ycsb.* to 'ycsb'@'%';
GRANT ALL ON ycsb.* to 'ycsb'@'localhost';
create database IF NOT EXISTS ycsb;

-- create sysbench user account
CREATE USER IF NOT EXISTS 'sbt'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'sbt'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON sbt.* to 'sbt'@'%';
GRANT ALL ON sbt.* to 'sbt'@'localhost';
create database IF NOT EXISTS sbt;

-- create arccion heartbeat 
-- enable arcion heartbeat to force flush

CREATE USER IF NOT EXISTS 'arcion'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'arcion'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON arcion.* to 'arcion'@'%';
GRANT ALL ON arcion.* to 'arcion'@'localhost';

GRANT ALL ON arcion.* to 'sbt'@'%';
GRANT ALL ON arcion.* to 'sbt'@'localhost';

GRANT ALL ON arcion.* to 'ycsb'@'%';
GRANT ALL ON arcion.* to 'ycsb'@'localhost';

create database IF NOT EXISTS arcion;

CREATE TABLE if not exists arcion.replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

describe arcion.replicate_io_cdc_heartbeat;

-- enable arcion replicant CDC 
-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'sbt'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'sbt'@'%';

-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;