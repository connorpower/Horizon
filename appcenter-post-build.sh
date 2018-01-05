#!/bin/sh

#  appcenter-post-build.sh
#  Horizon
#
#  Created by Connor Power on 05.01.18.
#  Copyright © 2018 Semantical GmbH & Co. KG. All rights reserved.

bash <(curl -s https://codecov.io/bash) -t 'c8c55ff6-8607-4513-a740-d3aa979e5c63' -J 'Horizon'
