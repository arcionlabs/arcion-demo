#!/usr/bin/env bash 

export_env() {
local TMPINI="${1:-/tmp/ini_menu.sh}"
local CFGINI="${2:-$CFG_DIR}"

cat >$TMPINI <<EOF
# source
export SRCDB_DIR="${SRCDB_DIR}"
export SRCDB_TYPE="${SRCDB_TYPE}"
export SRCDB_HOST="${SRCDB_HOST}"
export SRCDB_GRP="${SRCDB_GRP}"
export SRCDB_PORT="${SRCDB_PORT}"
export SRCDB_DB="${SRCDB_DB}"
export SRCDB_SID="${SRCDB_SID}"
# destination
export DSTDB_DIR="${DSTDB_DIR}"
export DSTDB_TYPE="${DSTDB_TYPE}"
export DSTDB_HOST="${DSTDB_HOST}"
export DSTDB_GRP="${DSTDB_GRP}"
export DSTDB_PORT="${DSTDB_PORT}"
export DSTDB_DB="${DSTDB_DB}"
export DSTDB_SID="${DSTDB_SID}"
# replication
export REPL_TYPE="${REPL_TYPE}"
export ARCION_ARGS="${ARCION_ARGS}"
# root id/password
export SRCDB_ROOT="${SRCDB_ROOT}"
export SRCDB_PW="${SRCDB_PW}"
export DSTDB_ROOT="${DSTDB_ROOT}"
export DSTDB_PW="${DSTDB_PW}"
# user id/password
export SRCDB_ARC_USER="${SRCDB_ARC_USER}"
export SRCDB_ARC_PW="${SRCDB_ARC_PW}"
export DSTDB_ARC_USER="${DSTDB_ARC_USER}"
export DSTDB_ARC_PW="${DSTDB_ARC_PW}"
# cfg
export CFG_DIR="${CFG_DIR}"
export LOG_ID="${LOG_ID}"
# JDBC
export SRCDB_JDBC_DRIVER="$SRCDB_JDBC_DRIVER"
export SRCDB_JDBC_URL="$SRCDB_JDBC_URL"
export SRCDB_JDBC_URL_IDPW="$SRCDB_JDBC_URL_IDPW"
export SRCDB_ROOT_URL="$SRCDB_ROOT_URL"
export DSTDB_JDBC_DRIVER="$DSTDB_JDBC_DRIVER"
export DSTDB_JDBC_URL="$DSTDB_JDBC_URL"
export DSTDB_JDBC_URL_IDPW="$DSTDB_JDBC_URL_IDPW"
export DSTDB_ROOT_URL="$DSTDB_ROOT_URL"
# JSQSH
export SRCDB_JSQSH_DRIVER="$SRCDB_JSQSH_DRIVER"
export DSTDB_JSQSH_DRIVER="$DSTDB_JSQSH_DRIVER"
# YCSB
export SRCDB_YCSB_DRIVER="$SRCDB_YCSB_DRIVER"
export DSTDB_YCSB_DRIVER="$DSTDB_YCSB_DRIVER"
# SCHEMA
export SRCDB_SCHEMA="${SRCDB_SCHEMA}"
export SRCDB_COMMA_SCHEMA="${SRCDB_COMMA_SCHEMA}"
export DSTDB_SCHEMA="${DSTDB_SCHEMA}"
export DSTDB_COMMA_SCHEMA="${DSTDB_COMMA_SCHEMA}"
# THREADS
export SRCDB_SNAPSHOT_THREADS="${SRCDB_SNAPSHOT_THREADS}"
export SRCDB_REALTIME_THREADS="${SRCDB_REALTIME_THREADS}"
export SRCDB_DELTA_SNAPSHOT_THREADS="${SRCDB_DELTA_SNAPSHOT_THREADS}"
export DSTDB_SNAPSHOT_THREADS="${DSTDB_SNAPSHOT_THREADS}"
export DSTDB_REALTIME_THREADS="${DSTDB_REALTIME_THREADS}"
# workload control
export max_cpus="$max_cpus"
export workload_rate="$workload_rate"
export workload_rate_bb="$workload_rate_bb"
export workload_threads="$workload_threads"
export workload_timer="$workload_timer"
export workload_timer_bb="$workload_timer_bb"
export workload_size_factor="$workload_size_factor"
export workload_modules_bb="$workload_modules_bb"
# benchbase
export SRCDB_BENCHBASE_TYPE="$SRCDB_BENCHBASE_TYPE"
export SRCDB_JDBC_ISOLATION="$SRCDB_JDBC_ISOLATION"
export SRCDB_JDBC_URL_BENCHBASE="$SRCDB_JDBC_URL_BENCHBASE"
export DSTDB_BENCHBASE_TYPE="$DSTDB_BENCHBASE_TYPE"
export DSTDB_JDBC_ISOLATION="$DSTDB_JDBC_ISOLATION"
export DSTDB_JDBC_URL_BENCHBASE="$DSTDB_JDBC_URL_BENCHBASE"
# confluent
export CONFLUENT_KEY_SECRET="`echo -n \"$CONFLUENT_CLUSTER_API_KEY:$CONFLUENT_CLUSTER_API_SECRET\" | base64 -w 0`"
# rewrite control
export SRCDB_JDBC_NO_REWRITE="$SRCDB_JDBC_NO_REWRITE"
export SRCDB_JDBC_REWRITE="$SRCDB_JDBC_REWRITE"
export DSTDB_JDBC_NO_REWRITE="$DSTDB_JDBC_NO_REWRITE"
export DSTDB_JDBC_REWRITE="$DSTDB_JDBC_REWRITE"
# oracle specific
# for multi tenant, c## is required
export SRCDB_USER_PREFIX="${SRCDB_USER_PREFIX}"
export DSTDB_USER_PREFIX="${DSTDB_USER_PREFIX}"
# gbq stuff
export GBQ_DST_PROJECT_ID="${GBQ_DST_PROJECT_ID}"
export GBQ_DST_SERVICE_EMAIL="${GBQ_DST_SERVICE_EMAIL}"
EOF
cp $TMPINI $CFGINI/.
}
