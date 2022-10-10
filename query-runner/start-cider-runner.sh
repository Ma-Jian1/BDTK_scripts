#!/bin/bash
# set -x

export PRESTO_SERVER=/workspace/code/presto/presto-native-execution/_build/debug/presto_cpp/main/presto_server
export WORKER_COUNT=1
export WORKER_ARGS="-enable_velox_plugin_BDTK"
export DATA_DIR=/workspace/tpch_data/parquet_sf1
export COORDINATOR_PORT="28082"
export WORKER_START_PORT=21234
export PUSHDOWN_FILTER="false"
export STORAGE_FORMAT="PARQUET"
# export TPCH_SCHEMA="sf1"
export ETC_DIR=/workspace/cider_etc

export CLASSPATH=$(< /workspace/script/query-runner/bin/cp.argfile)
java -server -Xmx10G -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError -Duser.timezone=America/Bahia_Banderas -Dhive.security=legacy -Dfile.encoding=UTF-8 com.facebook.presto.hive.HiveExternalWorkerQueryRunner