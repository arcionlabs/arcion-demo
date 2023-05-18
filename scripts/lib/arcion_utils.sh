#!/usr/bin/env bash 

. ${SCRIPTS_DIR}/lib/ping_utils.sh

# $1=yaml file
is_host_up() {
    local host=$( yq -r ".host" src.yaml )    
}

# return command parm given source and target pair
arcion_param() {
    local src_dir=${1:-.}
    local dst_dir=${2:-$src_dir}
    local meta_dir=${3:-$src_dir}
    local arg=""
    
    # source specific
    src=$(find ${src_dir} -maxdepth 1 -name src.yaml -print)
    filter=$(find ${src_dir} -maxdepth 1 -name src_filter.yaml -print)
    extractor=$(find ${src_dir} -maxdepth 1 -name src_extractor.yaml -print)

    # dest specific
    dst=$(find ${dst_dir} -maxdepth 1 -name dst.yaml -print)
    applier=$(find ${dst_dir} -maxdepth 1 -name dst_applier.yaml -print)

    # src to dst map
    case ${DSTDB_GRP,,} in 
        nullstorage | s3 )
            echo "removing mapper for ${DSTDB_GRP,,}" >&2
            ;;
        *)
            map=$(find ${dst_dir} -maxdepth 1 -name src_map.yaml -print)
            ;;
    esac

    # optional
    metadata=$(find ${meta_dir} -maxdepth 1 -name metadata.yaml -print)

    # construct the list
    arg="${src} ${dst}"
    [ ! -z "${filter}" ] && arg="${arg} --filter ${filter}"
    [ ! -z "${extractor}" ] && arg="${arg} --extractor ${extractor}"
    [ ! -z "${applier}" ] && arg="${arg} --applier ${applier}"
    [ ! -z "${map}" ] && arg="${arg} --map ${map}"
    [ ! -z "${metadata}" ] && arg="${arg} --metadata ${metadata}"

    echo "$arg" 
}
logreader_path() {
    local SRCDB_TYPE=${1}
    case "${SRCDB_TYPE,,}" in
        mysql)
            echo "/opt/mysql/usr/bin:$PATH"
            ;;
        mariadb)
            echo "/opt/mariadb/usr/bin:$PATH"
            ;;
        *)
            echo $PATH
            ;;
    esac
}

arcion_delta() {
    # do not run if gui will be used to invoke
    if [ "${gui_run}" = "1" ]; then 
        echo "GUI running Arcion.  Waiting for the timeout" >> $CFG_DIR/arcion.log
        return 0; 
    fi

    JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

    pushd $ARCION_HOME >/dev/null
    JAVA_HOME=$JAVA_HOME PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant delta-snapshot \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
    --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &
    export ARCION_PID=$!
    popd >/dev/null
}
arcion_real() {
    # do not run if gui will be used to invoke
    if [ "${gui_run}" = "1" ]; then 
        echo "GUI running Arcion.  Waiting for the timeout" >> $CFG_DIR/arcion.log
        return 0; 
    fi

    JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

    pushd $ARCION_HOME >/dev/null
    JAVA_HOME=$JAVA_HOME PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant real-time \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
    --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &
    export ARCION_PID=$!
    popd >/dev/null
}
arcion_full() {    
    # do not run if gui will be used to invoke
    if [ "${gui_run}" = "1" ]; then 
        echo "GUI running Arcion.  Waiting for the timeout" >> $CFG_DIR/arcion.log
        return 0; 
    fi

    JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

    pushd $ARCION_HOME >/dev/null
    JAVA_HOME=$JAVA_HOME PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant full \
    $( arcion_param ${CFG_DIR} ) \
     ${ARCION_ARGS} \
    --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &
    export ARCION_PID=$!
    popd >/dev/null
}
arcion_snapshot() {
    # do not run if gui will be used to invoke
    if [ "${gui_run}" = "1" ]; then 
        echo "GUI running Arcion.  Waiting for the timeout" >> $CFG_DIR/arcion.log
        return 0; 
    fi
    
    JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

    pushd $ARCION_HOME >/dev/null
    echo "$( arcion_param ${CFG_DIR} )"
    JAVA_HOME=$JAVA_HOME PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant snapshot \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
    --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &
    export ARCION_PID=$!
    popd >/dev/null
}
# find source DB dir that has src.yaml, filter.yaml and extractor.yarm
find_srcdb() {
    find * -type f \( -iname "src.yaml" -o -iname "src_filter*.yaml" -o -iname "src_extractor.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do if (( count == 3 )); then echo $dir; fi; done 
}
# find dst DB dir that has dst.yaml, applier.yaml 
find_dstdb() {
    find * -type f \( -iname "dst.yaml" -o -iname "dst_applier.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do 
        if (( count == 2 )); then echo $dir; fi; 
    done
}

find_hosts() {
    mkdir -p /tmp/arcion/nmap
    if [ ! -f "/tmp/arcion/nmap/names.$$.txt" ]; then
        ip=$( hostname -i | awk -F'.' '{print $1 "." $2 "." $3 "." 0 "/24"}' )
        nmap -sn -oG /tmp/arcion/nmap/names.$$.txt $ip >/dev/null
    fi
    cat /tmp/arcion/nmap/names.$$.txt | grep "arcnet" | awk -F"[ \(\)]" '{print $4}'
}

ask_src_host() {
    PS3="Please enter the SOURCE host: "
    options=( $(find_hosts) )
    select SRCDB_HOST in "${options[@]}"; do
        if [ ! -z "$SRCDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_HOST
}
ask_dst_host() {
    PS3='Please enter the DESTINATION host: '
    options=( $(find_hosts) )
    select DSTDB_HOST in "${options[@]}"; do
        if [ ! -z "$DSTDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_HOST
}
ask_src_dir() {
    PS3='Please enter the source dir: '
    options=( $(find_srcdb) )
    select SRCDB_DIR in "${options[@]}"; do
        if [ -d "$SRCDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_DIR
}
ask_dst_dir() {
    PS3='Please enter the target: '
    options=( $(find_dstdb) )
    select DSTDB_DIR in "${options[@]}"; do
        if [ -d "$DSTDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_DIR
}
ask_repl_mode() {
    PS3='Please enter the replication type: '
    options=( "snapshot" "full" "real-time" "delta-snapshot" )
    select REPL_TYPE in "${options[@]}"; do
        if [ ! -z "$REPL_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export REPL_TYPE
}
init_src() {
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0

    banner $SRCDB_HOST
    for f in $( find $CFG_DIR -maxdepth 1 -name src.init*sh ); do
        echo "Running $f"
        # NOTE: do not remove () below as that will exit this script
        ( exec ${f} 2>&1 | tee -a $f.log ) 
        if [ ! -z "$( cat $f.log | grep -i failed )" ]; then rc=1; fi  
    done
    mkdir -p $CFG_DIR/exit_status
    echo "$rc" > $CFG_DIR/exit_status/init_src.log
    return $rc
}
init_dst() {
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0    

    banner $DSTDB_HOST
    for f in $( find $CFG_DIR -maxdepth 1 -name dst.init*sh ); do
        echo "Running $f"
        # NOTE: do not remove () below as that will exit this script
        ( exec ${f} 2>&1 | tee -a $f.log ) 
        if [ ! -z "$( cat $f.log | grep -i failed )" ]; then rc=1; fi  
    done
    mkdir -p $CFG_DIR/exit_status
    echo "$rc" > $CFG_DIR/exit_status/init_dst.log
    return $rc
}

set_src() {
# source
SRCDB_HOST_old=${SRCDB_HOST}
SRCDB_DIR_old=${SRCDB_DIR}
SRCDB_TYPE_old=${SRCDB_TYPE}
SRCDB_GRP_old=${SRCDB_GRP}
SRCDB_PORT_old=${SRCDB_PORT}
SRCDB_ROOT_old=${SRCDB_ROOT}
while [ 1 ]; do
    clear
    echo "Setting up Source Host and Type"
    ask=0
    if [ -z "${SRCDB_HOST}" ]; then ask=1; ask_src_host; fi
    if [ -z "${SRCDB_DIR}" ]; then export SRCDB_DIR=$( infer_dbdir "${SRCDB_HOST}" ); fi
    if [ -z "${SRCDB_DIR}" -o ! -d "${SRCDB_DIR}" ]; then ask=1; ask_src_dir; fi
    if [ ! -z "${SRCDB_SUBDIR}" ]; then SRCDB_DIR=${SRCDB_DIR}/${SRCDB_SUBDIR}; fi

    export SRCDB_PROFILE_CSV=$(find_in_csv PROFILE_CSV ${SRCDB_HOST})
    declare -A SRCDB_PROFILE=(); csv_as_dict SRCDB_PROFILE "${PROFILE_HEADER}" "${SRCDB_PROFILE_CSV}"

    [ -z "${SRCDB_TYPE}" ] && export SRCDB_TYPE=$( map_dbtype "${SRCDB_HOST}" )
    [ -z "${SRCDB_GRP}" ] && export SRCDB_GRP=$( map_dbgrp "${SRCDB_TYPE}" )
    [ -z "${SRCDB_PORT}" ] && export SRCDB_PORT=$( map_dbport "${SRCDB_TYPE}" )
    [ -z "${SRCDB_ROOT}" ] && export SRCDB_ROOT=$( map_dbroot "${SRCDB_TYPE}" )
    [ -z "${SRCDB_PW}" ] && export SRCDB_PW=$( map_dbrootpw "${SRCDB_TYPE}" )
    [ -z "${SRCDB_SID}" ] && export SRCDB_SID=$( map_sid "${SRCDB_TYPE}" )
    [ -z "${SRCDB_ROOT_DB}" ] && export SRCDB_ROOT_DB=$( ${SRCDB_PROFILE[root_db]} )

    case "${SRCDB_GRP,,}" in
        snowflake)
            SRCDB_HOST="${SNOW_SRC_ENDPOINT}" 
            SRCDB_PORT="${SNOW_SRC_PORT:-443}" 
            SRCDB_ARC_USER="${SNOW_SRC_ID}" 
            SRCDB_ARC_PW="${SNOW_SRC_SECRET}"                 
            ;;
        informix)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA="${SRCDB_ARC_USER}"
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER}
        ;;
        db2)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA="${SRCDB_ARC_USER^^}"
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA^^}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER^^}
        ;;
        oracle)
            export SRCDB_ARC_USER="c##${SRCDB_ARC_USER}"
            export SRCDB_SCHEMA="${SRCDB_ARC_USER^^}"
            export SRCDB_COMMA_SCHEMA=${SRCDB_SCHEMA^^}
            export SRCDB_DB=""

            export ORA_LOG_PATH=${SRCDB_PROFILE[log_path]}
            export ORA_ARCH_LOG_PATH=${SRCDB_PROFILE[archive_log_path]}
            export ORA_ALT_LOG_PATH=${SRCDB_PROFILE[alt_log_path]}
            export ORA_ALT_ARCH_LOG_PATH=${SRCDB_PROFILE[alt_archive_log_path]}   
        ;;
        *)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA=$( map_dbschema "${SRCDB_TYPE}" )
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER}
        ;; 
    esac

    [ -z "${SRCDB_BENCHBASE_TYPE}" ] && export SRCDB_BENCHBASE_TYPE=$( map_benchbase_type "${SRCDB_TYPE}" )
    [ -z "${SRCDB_JDBC_ISOLATION}" ] && export SRCDB_JDBC_ISOLATION=$( map_benchbase_isolation "${SRCDB_TYPE}" )

    # safeguard RAM for the demo
    case "${SRCDB_TYPE,,}" in
        singlestore)
            workload_size_factor_bb=1
            echo "singlestore: setting workload_size_factor_bb=1"
            ;;
    esac

    echo "Source Host: ${SRCDB_HOST}"
    echo "Source Dir: ${SRCDB_DIR}"
    echo "Source Type: ${SRCDB_TYPE}"
    echo "Source Grp: ${SRCDB_GRP}"
    echo "Source Port: ${SRCDB_PORT}"
    echo "Source Root: ${SRCDB_ROOT}"
    echo "Source Schema: ${SRCDB_SCHEMA}"
    echo "Source DB: ${SRCDB_DB}"
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            SRCDB_HOST=${SRCDB_HOST_old}
            SRCDB_DIR=${SRCDB_DIR_old} 
            SRCDB_TYPE=${SRCDB_TYPE_old} 
            SRCDB_GRP=${SRCDB_GRP_old}
            SRCDB_PORT=${SRCDB_PORT_old}                
            SRCDB_ROOT=${SRCDB_ROOT_old}                
        fi
    fi
done
}

# destination
set_dst() {
DSTDB_HOST_old=${DSTDB_HOST}
DSTDB_TYPE_old=${DSTDB_TYPE}
DSTDB_DIR_old=${DSTDB_DIR}
DSTDB_GRP_old=${DSTDB_GRP}
DSTDB_PORT_old=${DSTDB_PORT}
DSTDB_ROOT_old=${DSTDB_ROOT}
while [ 1 ]; do
    clear
    echo "Setting up Target Host and Type"
    ask=0
    if [ -z "${DSTDB_HOST}" ]; then ask=1; ask_dst_host; fi
    if [ -z "${DSTDB_DIR}" ]; then export DSTDB_DIR=$( infer_dbdir "${DSTDB_HOST}" ); fi
    if [ -z "${DSTDB_DIR}" -o ! -d "${DSTDB_DIR}" ]; then ask=1; ask_dst_dir; fi
    if [ ! -z "${DSTDB_SUBDIR}" ]; then DSTDB_DIR=${DSTDB_DIR}/${DSTDB_SUBDIR}; fi

    export DSTDB_PROFILE_CSV=$(find_in_csv PROFILE_CSV ${DSTDB_HOST})
    declare -A DSTDB_PROFILE=(); csv_as_dict SRCDB_PROFILE "${PROFILE_HEADER}" "${DSTDB_PROFILE_CSV}"

    [ -z "${DSTDB_TYPE}" ] && export DSTDB_TYPE=$( map_dbtype "${DSTDB_HOST}" )
    [ -z "${DSTDB_GRP}" ] && export DSTDB_GRP=$( map_dbgrp "${DSTDB_TYPE}" )
    [ -z "${DSTDB_PORT}" ] && export DSTDB_PORT=$( map_dbport "${DSTDB_TYPE}" )
    [ -z "${DSTDB_ROOT}" ] && export DSTDB_ROOT=$( map_dbroot "${DSTDB_TYPE}" )
    [ -z "${DSTDB_PW}" ] && export DSTDB_PW=$( map_dbrootpw "${DSTDB_TYPE}" )
    [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=$( map_dbschema "${DSTDB_TYPE}" )
    [ -z "${DSTDB_SID}" ] && export DSTDB_SID=$( map_sid "${DSTDB_TYPE}" )
    [ -z "${DSTDB_ROOT_DB}" ] && export DSTDB_ROOT_DB=$( ${DSTDB_PROFILE[root_db]} )

    case "${DSTDB_GRP,,}" in
        bigquery)
            mkdir -p ${CFG_DIR}/gbq/dst
            echo $GBQ_DST_SECRET | base64 -d | gunzip > ${CFG_DIR}/gbq/dst/secret.json
            export GBQ_DST_PROJECT_ID=$(jq -r ".project_id" ${CFG_DIR}/gbq/dst/secret.json) 
            export GBQ_DST_SERVICE_EMAIL=$(jq -r ".client_email" ${CFG_DIR}/gbq/dst/secret.json)

            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=$( map_dbschema "${DSTDB_TYPE}" )
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
            ;;
        snowflake)
            DSTDB_HOST="${SNOW_DST_ENDPOINT}" 
            DSTDB_PORT="${SNOW_DST_PORT:-443}" 
            DSTDB_ARC_USER="${SNOW_DST_ID}" 
            DSTDB_ARC_PW="${SNOW_DST_SECRET}"                 

            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=$( map_dbschema "${DSTDB_TYPE}" )
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}            
            ;;
        informix)
            # HACK: for Informix, schema is same as the user name
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA="${DSTDB_ARC_USER}"
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
        ;;
        db2)
            # HACK: for Informix, schema is same as the user name
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA="${DSTDB_ARC_USER^^}"
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA^^}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER^^}
        ;;
        oracle)
            # HACK: for Oracle, comma schema is always blank
            export DSTDB_ARC_USER="c##${DSTDB_ARC_USER}"
            export DSTDB_SCHEMA="${DSTDB_ARC_USER^^}"
            export DSTDB_COMMA_SCHEMA=""
            export DSTDB_DB=""
        ;;
        *)
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=$( map_dbschema "${DSTDB_TYPE}" )
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
        ;; 
    esac

    [ -z "${DSTDB_BENCHBASE_TYPE}" ] && export DSTDB_BENCHBASE_TYPE=$( map_benchbase_type "${DSTDB_TYPE}" )
    [ -z "${DSTDB_JDBC_ISOLATION}" ] && export DSTDB_JDBC_ISOLATION=$( map_benchbase_isolation "${DSTDB_TYPE}" )

    echo "Destination Host: ${DSTDB_HOST}"
    echo "Destination Dir: ${DSTDB_DIR}"
    echo "Destination Type: ${DSTDB_TYPE}"
    echo "Destination Grp: ${DSTDB_GRP}"
    echo "Destination Port: ${DSTDB_PORT}"    
    echo "Destination Root: ${DSTDB_ROOT}"    
    echo "Destination Schema: ${DSTDB_SCHEMA}"    
    echo "Destination DB: ${DSTDB_DB}"    
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            DSTDB_HOST=${DSTDB_HOST_old}
            DSTDB_DIR=${DSTDB_DIR_old}   
            DSTDB_TYPE=${DSTDB_TYPE_old}   
            DSTDB_GRP=${DSTDB_GRP_old}
            DSTDB_PORT=${DSTDB_PORT_old}               
            DSTDB_ROOT=${DSTDB_ROOT_old}               
        fi
    fi
done
}
