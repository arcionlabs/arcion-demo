#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
SRCDB_TYPE=${SRCDB_TYPE:-postgres}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

CRL_ROOT_USER=${CRL_ROOT_USER:-root}
CRL_ROOT_PW=${CRL_ROOT_PW:-password}
CRL_PORT=26257

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}


export PGCLIENTENCODING='utf-8'

wait_pg () {
  local host=$1
  local user=${2:-root}
  local pw=${3:-password}
  local port=${4:-26257}
  rc=1
  while [ ${rc} != 0 ]; do
    psql -l postgresql://${user}:${pw}@${host}:${port}/defaultdb?sslmode=disable #>/dev/null 2>&1
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${host} as ${user} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
wait_pg ${SRCDB_HOST} ${CRL_ROOT_USER} ${CRL_ROOT_PW}

# setup database permissions
banner pg

cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sql | psql postgresql://${CRL_ROOT_USER}:${CRL_ROOT_PW}@${SRCDB_HOST}:${CRL_PORT}/defaultdb?sslmode=disable
cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.arcsrc.sql | psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable

# sysbench data population
banner sysbench 

sbtest1_cnt=$(psql --csv -t postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable <<EOF
select count(*) from sbtest1; 
EOF
)

if [[ ${sbtest1_cnt} == "0" || ${sbtest1_cnt} == "" ]]; then
  sysbench oltp_read_write --pgsql-host=${SRCDB_HOST} --auto_inc=off --db-driver=pgsql --pgsql-user=${ARCSRC_USER} --pgsql-password=${ARCSRC_PW} --pgsql-db=${ARCSRC_USER} prepare --pgsql-port=${CRL_PORT}
fi

psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable <<EOF
select count(*) from sbtest1; 
select sum(k) from sbtest1;
select * from sbtest1 limit 1;
EOF

# ycsb data population 
banner ycsb 

usertable_cnt=$(psql --csv -t postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable <<EOF
select count(*) from usertable; 
EOF
)

pushd ${YCSB}
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver  -p db.url="jdbc:postgresql://${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable&reWriteBatchedInserts=true" -p db.user=${ARCSRC_USER} -p db.passwd=${ARCSRC_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000
fi

psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}:${CRL_PORT}/${ARCSRC_USER}?sslmode=disable <<EOF
select count(*) from usertable; 
select * from usertable limit 1;
EOF

popd
