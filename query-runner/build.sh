#/bin/bash

ACTION="${1:-"keep"}"

if [ x$ACTION = x"reinstall" ]; then
    pushd /workspace/code/presto/
    ./mvnw clean install -DskipTests
    if [ $? -ne 0 ]; then
        echo "install presto jar failed"
        exit
    fi

    rm -f /workspace/script/query-runner/bin/cp.argfile
    rm -f /workspace/script/query-runner/bin/cli-cp.argfile

    ./mvnw dependency:build-classpath -f /workspace/code/presto/presto-native-execution/pom.xml | grep "/root/.m2/repository" | tee /workspace/script/query-runner/bin/cp.argfile
    ./mvnw dependency:build-classpath -f /workspace/code/presto/presto-native-execution/pom.xml | grep "/root/.m2/repository" | tee /workspace/script/query-runner/bin/cli-cp.argfile

    sed -i "s|$|:/workspace/script/query-runner/bin|" /workspace/script/query-runner/bin/cp.argfile
    sed -i "s|$|:/workspace/code/presto/presto-cli/target/classes:/root/.m2/repository/net/sf/opencsv/opencsv/2.3/opencsv-2.3.jar|" /workspace/script/query-runner/bin/cli-cp.argfile
    popd
fi

pushd /workspace/script/query-runner/
rm -rf ./bin/HiveExternalWorkerQueryRunner.class
javac -cp $(< ./bin/cp.argfile) -d ./bin -encoding utf8 ./com/facebook/presto/hive/HiveExternalWorkerQueryRunner.java
popd