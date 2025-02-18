#!/bin/bash

TABLE_PATH="/var/tmp/user-card-mapping.table"

MAPPING_TABLE=(
"joshua:3019d4e739da739ced39ce739d836858210842108421c84210c3eb341018d0e48becd1f91b91f845089e9b3e13350832303330303130313e00fe00"
"user1:3019d4e739da739ced39ce739d836858210842108421c84210c3eb341018d0e48becd1f91b91f845089e9b3e13350832303330303130313e00fe00:B549D7112F6762C1C917F0947C401DC98CEE2CEA"
)

# In Jamf Pro, parameters 1–3 are predefined as mount point, computer name, and username.
if [ "$4" = "dump" ]; then
  cat /dev/null > ${TABLE_PATH}
  for line in "${MAPPING_TABLE[@]}"; do
    echo "${line}" >> ${TABLE_PATH}
  done
fi
