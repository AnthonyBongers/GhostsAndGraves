#!/bin/bash

brew list cc65 || brew install cc65
brew list clang-format || brew install clang-format
brew list watchman || brew install watchman

curl https://raw.githubusercontent.com/nlohmann/json/620034ececc93991c5c1183b73c3768d81ca84b3/single_include/nlohmann/json.hpp -o ./utils/src/shared/json.hpp

