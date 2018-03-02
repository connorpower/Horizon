#!/bin/bash
#
#  spm-init.sh
#  -----------
#  Created by Connor Power on 02.03.18.
#  Copyright © Connor Power. All rights reserved.
#

set -x
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )"; pwd)"

if ! which swift > /dev/null; then
    echo "warning: swift is not installed."
    exit 1
fi

swift package update && swift package generate-xcodeproj --xcconfig-overrides="${SCRIPT_DIR}/Configuration.xcconfig"

