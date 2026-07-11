#!/bin/sh
# Use full Xcode.app when xcode-select points at Command Line Tools.
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

# Ensure child build processes (including Dart native-asset hooks) can locate
# the iOS simulator SDK even when xcode-select is not switched.
XCODE_ENV_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="${XCODE_ENV_DIR}/bin:${PATH}"
