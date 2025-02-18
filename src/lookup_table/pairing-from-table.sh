#!/bin/bash

TABLE_PATH="/var/tmp/user-card-mapping.table"

#TOKEN_DRIVER_CLASS_ID="com.apple.pivtoken"
TOKEN_DRIVER_CLASS_ID="com.authentrend.securityKeyDesktop.atPivToken"

quit_with_msg() {
  echo "message: $1" >> ${DIALOG_FILE} && sleep 0.1
  echo "progress: complete" >> ${DIALOG_FILE} && sleep 0.1
  echo "progresstext: Done" >> ${DIALOG_FILE} && sleep 0.1
  quit $2
}

find_user_card_mapping_from_array() {
  for item in "${MAPPING_TABLE[@]}"; do
    if [[ "${item}" == "$1:"* ]]; then
      echo "${item}"
      break
    fi
  done
}

find_user_card_mapping_from_file() {
  sed -n "/$1:/p" ${TABLE_PATH}
}

if [ $# -ne 2 ]; then
  exit 1
fi

USERNAME=$1
DIALOG_FILE=$2
USER_CARD_MAPPING=

echo "progresstext: Searching..." >> ${DIALOG_FILE} && sleep 0.1
if [ ${#MAPPING_TABLE[@]} -gt 0 ]; then
  USER_CARD_MAPPING=$(find_user_card_mapping_from_array ${USERNAME})
else
  USER_CARD_MAPPING=$(find_user_card_mapping_from_file ${USERNAME})
fi
echo "${USER_CARD_MAPPING}"
if [ "${USER_CARD_MAPPING}" = "" ]; then
  MSG="User '${USERNAME}' not found"
  quit_with_msg "${MSG}" 1
fi

CHUID=$(echo "${USER_CARD_MAPPING}" | awk -F':' '{print $2}')
HASH=$(echo "${USER_CARD_MAPPING}" | awk -F':' '{print $3}')

# security list-smartcards will list nothing on Apple Silicon MacBook
#GUIDS=$(security list-smartcards | grep ${TOKEN_DRIVER_CLASS_ID} | awk -F':' '{print $2}' | tr '\n' ' ')
GUIDS=$(sc_auth identities | grep "SmartCard:" | awk '{print $2}' | grep ${TOKEN_DRIVER_CLASS_ID} | awk -F':' '{print $2}' | tr '\n' ' ')
TOKEN_ID=
for guid in ${GUIDS}; do
  echo "${USER_CARD_MAPPING}" | grep -i ${guid} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    TOKEN_ID="${TOKEN_DRIVER_CLASS_ID}:${guid}"
    break
  fi
done
if [ "${TOKEN_ID}" = "" ]; then
  MSG="PIV smart card or driver not found (${LINENO})"
  quit_with_msg "${MSG}" 1
fi

if [ "${HASH}" = "" ]; then
  IDENTITIES=$(sc_auth identities)
  total_line=$(echo "${IDENTITIES}" | wc -l)
  start_line=$(echo "${IDENTITIES}" | awk '/'"${TOKEN_ID}"'/{print NR}' | head -n 1)
  if [ "${start_line}" = "" ]; then
    MSG="PIV smart card or driver not found (${LINENO})"
    quit_with_msg "${MSG}" 1
  fi
  IDENTITIES=$(echo "${IDENTITIES}" | tail -n $(expr ${total_line} - ${start_line}))
  end_line=$(echo "${IDENTITIES}" | awk '/'"${TOKEN_ID}"'/{print NR}' | head -n 1)
  if [ "${end_line}" != "" ]; then
    IDENTITIES=$(echo "${IDENTITIES}" | head -n $(expr ${end_line} - 1))
  fi
  HASH=$(echo "${IDENTITIES}" | awk '/Certificate For PIV Authentication/' | awk '{print $1}' | head -n 1)
  if [ "${HASH}" = "" ]; then
    MSG="Certificate for PIV Authentication not found (${LINENO})"
    quit_with_msg "${MSG}" 1
  fi
fi

sc_auth list -u ${USERNAME} | grep -i ${HASH} > /dev/null 2>&1
if [ $? -eq 0 ]; then
  MSG="PIV smart card has already been paired"
  quit_with_msg "${MSG}" 0
fi

echo "progresstext: Pairing..." >> ${DIALOG_FILE} && sleep 0.1
sc_auth pair -h ${HASH} -u ${USERNAME}
result=$?
MSG="PIV smart card has been paired"
if [ ${result} -ne 0 ]; then
  MSG="Unable to pair PIV smart card (${LINENO})"
fi

sc_auth enable_for_login -c ${TOKEN_DRIVER_CLASS_ID}

quit_with_msg "${MSG}" ${result}
