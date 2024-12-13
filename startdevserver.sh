#!/bin/bash

watchman-make \
  -p "src/**/*.asm" "assets/**/*" "nes.cfg" -t build \
  -p "raw/**/*" "Makefile*" -t generate \
  -p "utils/src/*.cpp" "utils/src/shared/*.hpp" "utils/src/*.h" -t build_utils
