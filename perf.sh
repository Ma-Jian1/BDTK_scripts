#!/bin/bash
set -x

RED='\033[0;31m'
NC='\033[0m' # No Color
WORKER=/workspace/code/presto/presto-native-execution/_build/release/presto_cpp/main/presto_server
ETC_DIR=/workspace/native_etc
QUERY_DIR=/workspace/code/presto/presto-native-execution/src/test/resources/tpch/queries

rm -f presto.log
rm -f presto-cli.log
${WORKER} -etc_dir=${ETC_DIR} 2>&1 > /dev/null &
sleep 2
PID=`pidof -x presto_server`

for i in {1..22}
do
    echo ${i}
    perf_file="/workspace/tpch_data/perf/perf.data.sql.q${i}"
    rm -f ${perf_file}
    
    perf record -e cycles:u --call-graph dwarf -F 4999 -m 256M -p ${PID} -o ${perf_file} &
    sleep 1

    # presto-cli --catalog hive --schema tpch -f ${QUERY_DIR}/q${i}.sql 2>&1 > /dev/null
    bash /workspace/script/query-runner/preto-cli.sh -f ${QUERY_DIR}/q${i}.sql 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}sql ${i} failed${NC}"
        pkill -9 perf
        pkill -9 presto_server
        rm -f perf.data.sql.q${i}
    fi
    sleep 1

    pkill perf
    while pidof -x perf
    do
        sleep 1
    done
done

pkill -9 presto_server
