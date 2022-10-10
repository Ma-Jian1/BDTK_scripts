#!/bin/bash

set -x

RED='\033[0;31m'
NC='\033[0m' # No Color

pushd code/BDTK
# git config --global --add safe.directory /workspace/code/BDTK
git fetch --all -v
if [ $? -ne 0 ]; then
    echo "update BDTK failed"
    exit
fi
git submodule sync
git submodule update --init --recursive
popd

pushd code/BDTK/thirdparty/velox
# git config --global --add safe.directory /workspace/code/BDTK/thirdparty/velox
BRANCH_NAME=`git branch -r --contains HEAD | cut -d' ' -f3`
echo -e "${RED}branch name: ${BRANCH_NAME}${NC}"
popd

pushd code/presto
# git config --global --add safe.directory /workspace/code/presto
git fetch
if [ $? -ne 0 ]; then
    echo "update presto failed"
    exit
fi
git switch ${BRANCH_NAME} --detach
git submodule sync
git submodule update --init --recursive

sed -i "|<module>presto-docs</module>|<!-- <module>presto-docs</module> -->|" pom.xml
echo "velox-plugin" >> .gitignore
popd