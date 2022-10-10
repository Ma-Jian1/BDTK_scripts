#!/bin/bash
set -x

jq -s '.[0] + .[1]' /workspace/compile_commands.json /workspace/code/build.llvm-9.0.1/compile_commands.json > /workspace/compile_commands.json