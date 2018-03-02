#! /bin/bash

set -x
set -e

if ! which swift > /dev/null; then
    echo "warning: swift is not installed."
    exit 1
fi

swift package update && swift package generate-xcodeproj --xcconfig-overrides=Configuration.xcconfig

