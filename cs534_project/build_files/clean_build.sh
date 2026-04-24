#!/bin/bash

if [[ -z "$ILLIXR_HOME" ]]; then
  echo "Error: ILLIXR_HOME is not set"
  exit 1
fi

cd ${ILLIXR_HOME}/build 

rm -f CMakeCache.txt

rm -rf CMakeFiles/
