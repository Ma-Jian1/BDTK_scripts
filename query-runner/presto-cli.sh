#!/bin/bash

export CLASSPATH=$(< /workspace/script/query-runner/bin/cli-cp.argfile)
java -client -Xmx4G -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError com.facebook.presto.cli.Presto --catalog hive --schema tpch $@