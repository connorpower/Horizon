#!/bin/bash

#  increase_build_number.sh
#  Horizon
#
#  Created by Connor Power on 28.12.17.
#  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.

echo "Bumping build number..."
plist=${PROJECT_DIR}/${INFOPLIST_FILE}
branch=$(git rev-parse --abbrev-ref HEAD)

buildnum=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${plist}")
if [[ "${buildnum}" == "" ]]; then
echo "No build number in $plist"
exit 2
fi

buildnum=$(expr $buildnum + 1)
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "${plist}"
echo "Bumped build number to $buildnum"

echo "Committing the build number..."
cd ${PROJECT_DIR};
cd ${PROJECT_DIR};git add "${plist}"
cd ${PROJECT_DIR};git commit --author="Xcode Bot <noreply@semantical.com>" -m "Bumped the build number"
cd ${PROJECT_DIR};git push -u origin "$branch"
echo "Build number committed."
