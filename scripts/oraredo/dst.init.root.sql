-- II. Set up Oracle User

CREATE USER ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER} IDENTIFIED BY ${DSTDB_ARC_PW};

ALTER USER ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER} quota unlimited on USERS;

GRANT CREATE SESSION TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

GRANT
    SELECT ANY TABLE,
    INSERT ANY TABLE,
    UPDATE ANY TABLE,
    DELETE ANY TABLE,
    CREATE ANY TABLE,
    ALTER ANY TABLE,
    DROP ANY TABLE
    TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

GRANT
    CREATE ANY SEQUENCE,
    SELECT ANY SEQUENCE,
    CREATE ANY INDEX
    TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

GRANT SET CONTAINER TO  ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER} CONTAINER=ALL;

GRANT SELECT ON DBA_PDBS to ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER} CONTAINER=ALL;

-- required even non CDC
GRANT SELECT ON gv_\$instance TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- 3 CDC

GRANT EXECUTE_CATALOG_ROLE TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT LOGMINING TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};


GRANT SELECT ON v_\$logmnr_contents TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$archived_log TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$logfile TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
-- below Oracle 19c
GRANT SELECT ON v_\$logfile TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- Enable logs on database
-- https://docs.arcion.io/docs/source-setup/oracle/setup-guide/oracle-traditional-database/#enable-logs
-- not having this will result in
-- CDC not enabled
ALTER DATABASE FORCE LOGGING;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
--

GRANT CREATE SESSION TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ANY TABLE TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

GRANT SELECT ON gv_\$instance TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$PDBS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$log TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$database_incarnation to ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- 4 setup global permissions
-- https://docs.arcion.io/docs/source-setup/oracle/setup-guide/oracle-traditional-database/#iv-set-up-global-permissions

-- onetime
GRANT SELECT ON DBA_SEGMENTS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- snapshot and CDC
GRANT SELECT ON gv_\$database TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON gv_\$transaction TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
--Not required for replicant release 20.8.13.7 and above
GRANT SELECT ON gv_\$session TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- CDC
GRANT FLASHBACK ANY TABLE TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

-- schema migration
GRANT SELECT ON ALL_TABLES TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_VIEWS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_CONSTRAINTS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_CONS_COLUMNS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_PART_TABLES TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_PART_KEY_COLUMNS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON ALL_TAB_COLUMNS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON SYS.ALL_INDEXES TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON SYS.ALL_IND_COLUMNS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};
GRANT SELECT ON SYS.ALL_IND_EXPRESSIONS TO ${DSTDB_USER_PREFIX}${DSTDB_ARC_USER};

