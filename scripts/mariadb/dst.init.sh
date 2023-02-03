#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

PG_ROOT_USER=${PG_ROOT_USER:-postgres}
PG_ROOT_PW=${PG_ROOT_PW:-password}

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}

# note the convention to save the output /tmp/arcion/${DSTDB_HOST}

# with root user
if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql ]; then
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql | mysql -h${DSTDB_HOST} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PW} --verbose 2>&1 | tee /tmp/arcion/${DSTDB_HOST}/dst.init.log
fi

# with the arcsrc user
if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcdst.sql ]; then
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcdst.sql | mysql -h${DSTDB_HOST} -u${ARCDST_USER} -p${ARCDST_PW} --verbose 2>&1 | tee /tmp/arcion/${DSTDB_HOST}/dst.init.arcdst.log
fi
