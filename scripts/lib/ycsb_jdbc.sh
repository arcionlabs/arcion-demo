#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh

# defaults for the command line
export default_ycsb_rate=1
export default_ycsb_threads=1
export default_ycsb_timer=600
export default_ycsb_size_factor=1
export default_ycsb_table="usertable"

# command line arguments
export ycsb_rate=${default_ycsb_rate}
export ycsb_threads=${default_ycsb_threads}
export ycsb_timer=${default_ycsb_timer}
export ycsb_size_factor=${default_ycsb_size_factor}

# constants
export const_ycsb_insertstart=0
export const_ycsb_recordcount=100000
export const_ycsb_operationcount=1000000000
export const_ycsb_zeropadding=11

ycsb_usage() {
  echo "ycsb: override on the command line or set
    -r ycsb_rate=${default_ycsb_rate}
    -t ycsb_threads=${default_ycsb_threads}
    -w ycsb_timer=${default_ycsb_timer}
    -s ycsb_size_factor=${default_ycsb_size_factor}
  "
}

function ycsb_opts() {
  # these are args that can be overridden from the command line
  # override from command line
  local opt
  while getopts ":hr:s:t:w:" opt; do
      case $opt in
          h ) ycsb_usage ;;
          r ) args_ycsb_rate="$OPTARG" ;;
          t ) args_ycsb_threads="$OPTARG" ;;
          w ) args_ycsb_timer="$OPTARG" ;;
          s ) args_ycsb_size_factor="$OPTARG" ;;
      esac
  done
  [ "$args_ycsb_threads" = "0" ] && args_ycsb_threads=$(getconf _NPROCESSORS_ONLN)
}

ycsb_rows() {
  local LOC="${1:-src}"        # SRC|DST 
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  x=$( echo "select max(ycsb_key) from ${ycsb_table}; -m csv" | jdbc_cli ${LOC,,} "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo $x | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

ycsb_select_key() {
  local LOC="${1:-src}"        # SRC|DST 
  local ycsb_key="$2"
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  echo "select ycsb_key from ${ycsb_table} where ycsb_key='$ycsb_key'; -m csv" | jdbc_cli ${LOC,,} "-n -v headers=false -v footers=false"
}

ycsb_load() {    
  local ycsb_threads=${ycsb_threads:-${default_ycsb_threads}}
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  # want multirow inserts for supported DBs
  case "${db_grp,,}" in
    mysql)
      jdbc_url="${jdbc_url}&rewriteBatchedStatements=true"
      ;;
    postgresql)
      jdbc_url="${jdbc_url}&reWriteBatchedInserts=true"
      ;;
    # Does not improve perforamnce when autocommit=false
    # sqlserver)
    #  jdbc_url="${jdbc_url};useBulkCopyForBatchInsert=true"
    #  ;;
  esac 

  ycsbdir=$( cd ${YCSB}/*jdbc*${YCSB_VERSION}*/; pwd )
  ${ycsbdir}/bin/ycsb.sh load jdbc -s -threads ${ycsb_threads} \
    -p workload=site.ycsb.workloads.CoreWorkload \
    -p db.driver="${jdbc_driver}" \
    -p db.url="${jdbc_url}" \
    -p db.user=${db_user} \
    -p db.passwd=${db_pw} \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=false \
    -p jdbc.batchupdateapi=true \
    -p db.urlsharddelim='_' \
    -p db.batchsize=1024  \
    -p table=${ycsb_table} \
    -p insertstart=${ycsb_insertstart} \
    -p recordcount=${const_ycsb_recordcount} \
    -p requestdistribution=uniform \
    -p zeropadding=${const_ycsb_zeropadding} \
    -p insertorder=ordered
}

ycsb_load_sf() {
  local LOC="${1:-SRC}"        # SRC|DST

  local db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  local db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  local jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
  local jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
  local db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
  local db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" )  

  local ycsb_size_factor=${workload_size_factor}

  local ycsb_size_factor=${ycsb_size_factor:-${default_ycsb_size_factor}}
  local ycsb_insertstart=${ycsb_insertstart:-${const_ycsb_insertstart}}
  local ycsb_key 
  local key_found
  local i
  local ycsb_key_start=$(( $(ycsb_rows $LOC) / const_ycsb_recordcount ))

  echo "YCSB: starting from size factor $ycsb_key_start to ${ycsb_size_factor}"

  for i in $( seq ${ycsb_key_start} 1 $(( ycsb_size_factor-1 )) ); do 

    # ycsb key are padded 11 digits
    ycsb_key=$(printf user%0${const_ycsb_zeropadding}d ${ycsb_insertstart})

    # key already there? 
    echo -n "YCSB: Checking existance of ycsb_key ${ycsb_key}"
    key_found=$( ycsb_select_key $LOC $ycsb_key )

    # insert if not found
    if [ -z "${key_found}" ]; then 
      echo " not found.  start insert at ${ycsb_insertstart}"
      ycsb_load ${ycsb_insertstart}
    else
      echo " found.  skipping this factor"
    fi

    ycsb_insertstart=$(( ycsb_insertstart + const_ycsb_recordcount ))
  done
}

function ycsb_load_src() { 
  ycsb_load_sf src
}

function ycsb_load_dst() { 
  ycsb_load_sf dst
}
 
ycsb_run() {
  local LOC="${1:-SRC}"        # SRC|DST

  local db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  local db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  local jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
  local jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )

  local ycsb_rate=${workload_rate:-${default_ycsb_rate}}
  local ycsb_threads=${workload_threads:-${default_ycsb_threads}}
  local ycsb_timer=${workload_timer:-${default_ycsb_timer}}
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  local ycsb_recordcount=$(( $(ycsb_rows $LOC) ))

  local ycsb_insertstart=${ycsb_insertstart:-${const_ycsb_insertstart}}

  ${YCSB}/*jdbc*${YCSB_VERSION}*/bin/ycsb.sh run jdbc -s -threads ${ycsb_threads} -target ${ycsb_rate} \
  -p updateproportion=1 \
  -p readproportion=0 \
  -p workload=site.ycsb.workloads.CoreWorkload \
  -p requestdistribution=uniform \
  -p table=${ycsb_table} \
  -p recordcount=${const_ycsb_recordcount} \
  -p insertstart=${ycsb_insertstart} \
  -p operationcount=${const_ycsb_operationcount} \
  -p db.driver=${jdbc_driver} \
  -p db.url="${jdbc_url}" \
  -p db.user=${db_user} \
  -p db.passwd="${db_pw}" \
  -p db.batchsize=1024  \
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p db.urlsharddelim='_' \
  -p requestdistribution=uniform \
  -p zeropadding=11 \
  -p insertorder=ordered &    
  # save the PID  
  export YCSB_RUN_PID="$!"
  # wait for job to finish, expire, or killed by ctl-c
  trap kill_jobs SIGINT
  echo "ycsb waiting ${ycsb_timer}"
  wait_jobs "${ycsb_timer}"
  echo "ycsb waiting ${ycsb_timer} done"
  kill_jobs
}

function ycsb_run_src() {
  ycsb_run src
}

function ycsb_run_dst() {
  ycsb_run dst
}