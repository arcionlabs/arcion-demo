-- create arcsrc for retrivial
CREATE TABLE replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

-- ts is used for snapshot delta. 
CREATE TABLE usertable (
	ycsb_key VARCHAR(255) PRIMARY KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT
);

-- will only happen if source and destion was flipped
ALTER TABLE usertable DROP (ts2);

