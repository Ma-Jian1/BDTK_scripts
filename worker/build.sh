#!/bin/bash
set -x

TYPE="${1:-"debug"}"
ACTION="${2:-"keep"}"

PLUGIN_BUILD_DIR="build-${TYPE^}" # build-Debug / build-Release

pushd /workspace/code/presto/presto-native-execution

if [ x$ACTION = x"copy" ]; then
    rm -rf ./velox-plugin
    mkdir -p ./velox-plugin
    cp -r /workspace/code/BDTK/cider ./velox-plugin
    cp -r /workspace/code/BDTK/cider-velox ./velox-plugin
    cp -r /workspace/code/BDTK/thirdparty ./velox-plugin
    rm -rf ./velox-plugin/thirdparty/duckdb/data
    cp -r /workspace/code/BDTK/cmake-modules ./velox-plugin
    cp /workspace/code/BDTK/CMakeLists.txt ./velox-plugin
    cp /workspace/code/BDTK/Makefile ./velox-plugin
    sed -i 's/-DVELOX_ENABLE_PARQUET=ON/-DVELOX_ENABLE_PARQUET=ON -DCIDER_ENABLE_TESTS=OFF/g' ./velox-plugin/Makefile

    pushd ./velox-plugin
    make ${TYPE} 
    popd

    # rm -rf velox
    # cp -r /workspace/code/BDTK/thirdparty/velox ./velox
else
    pushd ./velox-plugin
    cmake --build ${PLUGIN_BUILD_DIR} -j 72
    popd
fi

if [ $? -ne 0 ]; then
    echo "compile velox-plugin failed"
    exit
fi

# copy the cider lib to presto_cpp
rm -rf ./presto_cpp/main/lib
mkdir -p ./presto_cpp/main/lib

# cider-velox
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider-velox/src/libvelox_plugin.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider-velox/src/ciderTransformer/libcider_plan_transformer.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider-velox/src/planTransformer/libvelox_plan_transformer.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider-velox/src/substrait/libvelox_substrait_convertor.a ./presto_cpp/main/lib

# cider
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/common/libcommon.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/exec/module/libcider.so ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/exec/expression/libcider_exec_expression.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/exec/template/libQueryEngine.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/function/libcider_function.a ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/type/data/libcider_type_data.a ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/type/plan/substrait/libsubstrait_eu_converter.a ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/type/plan/substrait/libsubstrait.a ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/type/schema/libcider_schema.a ./presto_cpp/main/lib
# cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/util/libutil.a ./presto_cpp/main/lib

# thirdparty
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/thirdparty/velox/velox/substrait/libvelox_substrait_plan_converter.a ./presto_cpp/main/lib
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/thirdparty/velox/third_party/yaml-cpp/libyaml-cpp.a ./presto_cpp/main/lib

sed -i 's/\"planTransformer\/PlanTransformer\.h\"/\"..\/planTransformer\/PlanTransformer\.h\"/' ./velox-plugin/cider-velox/src/ciderTransformer/CiderPlanTransformerFactory.h

# compile
if [ x$ACTION = x"copy" ]; then
    make clean
fi
make PRESTO_ENABLE_PARQUET=ON -j ${CPU_COUNT:-`nproc`} ${TYPE}
if [ $? -ne 0 ]; then
    echo "compile presto failed"
    exit
fi

rm -rf ./_build/debug/presto_cpp/function
mkdir ./_build/debug/presto_cpp/function
cp ./velox-plugin/${PLUGIN_BUILD_DIR}/cider/function/RuntimeFunctions.bc ./_build/debug/presto_cpp/function/

jq -s '.[0] + .[1]' ./_build/debug/compile_commands.json ./velox-plugin/${PLUGIN_BUILD_DIR}/compile_commands.json > /workspace/compile_commands.json

# rm -rf ./velox-plugin
popd