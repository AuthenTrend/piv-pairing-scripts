#!/bin/bash

JAMF_PRO_MODE=0

DIALOG_BIN_PATH="/usr/local/bin/dialog"
DIALOG_CMD_FILE=$(mktemp /var/tmp/piv-pairing-dialog.XXXXXX)
DIALOG_ICON_PATH="/System/Library/Frameworks/CryptoTokenKit.framework/ctkbind.app"

LOGGEDIN_USER=$(echo "show State:/Users/ConsoleUser" | scutil | grep kCGSSessionUserNameKey | awk -F':' '{print $2}' | tr -d '[:blank:]')
LOGGEDIN_UID=$(echo "show State:/Users/ConsoleUser" | scutil | grep kCGSSessionUserIDKey | awk -F':' '{print $2}' | tr -d '[:blank:]')

help() {
  echo
  echo -e "Usage:\n"
  echo -e "\t$0 <pair PAIRING_METHOD | unpair>"
  echo
}

quit() {
  echo "button1text: Quit" >> ${DIALOG_CMD_FILE} && sleep 0.1
  echo "button1: enable" >> ${DIALOG_CMD_FILE} && sleep 0.1
  rm -f ${DIALOG_CMD_FILE}
  exit $1
}

init_dialog() {
  TITLE=$1
  MESSAGE=$2
  if [ "${TITLE}" = "" ]; then
    TITLE=" "
  fi
  if [ "${MESSAGE}" = "" ]; then
    MESSAGE=" "
  fi
  DIALOG_ARGS=(
    "--title"
    "${TITLE}"
    "--titlefont"
    "size=14"
    "--message"
    "${MESSAGE}"
    #"--messagealignment"
    #"center"
    "--messageposition"
    "center"
    #"--ontop"
    "--width"
    "50%"
    "--height"
    "25%"
    "--progress"
    "--progresstext"
    " "
    #"--centreicon"
    "--icon"
    "${DIALOG_ICON_PATH}"
    "--iconsize"
    "100"
    "--button1text"
    "Quit"
    "--button1disabled"
    "Quit"
    "--commandfile"
    "${DIALOG_CMD_FILE}"
  )
  launchctl asuser "${LOGGEDIN_UID}" "${DIALOG_BIN_PATH}" "${DIALOG_ARGS[@]}" &
  sleep 0.5
}

unpair_piv() {
  init_dialog "PIV Smart Card Pairing Tool" "Unpairing..."
  echo "progresstext: Searching..." >> ${DIALOG_CMD_FILE} && sleep 0.1
  PAIRED_HASHES=$(sc_auth list -u ${LOGGEDIN_USER} | grep "Hash" | awk '{print $2}' | tr '\n' ' ')
  if [ "${PAIRED_HASHES}" = "" ]; then
    echo "message: No paired PIV smart card found" >> ${DIALOG_CMD_FILE} && sleep 0.1
  else
    echo "progresstext: Unpairing..." >> ${DIALOG_CMD_FILE} && sleep 0.1
    for HASH in ${PAIRED_HASHES}; do
      sc_auth unpair -h ${HASH} -u ${LOGGEDIN_USER}
    done
    PAIRED_HASHES=$(sc_auth list -u ${LOGGEDIN_USER} | grep "Hash" | awk '{print $2}' | tr '\n' ' ')
    if [ "${PAIRED_HASHES}" = "" ]; then
      echo "message: PIV smart card has been unpaired" >> ${DIALOG_CMD_FILE} && sleep 0.1
    else
      echo "message: Unable to unpair PIV smart card" >> ${DIALOG_CMD_FILE} && sleep 0.1
    fi
  fi
  echo "progress: complete" >> ${DIALOG_CMD_FILE} && sleep 0.1
  echo "progresstext: Done" >> ${DIALOG_CMD_FILE} && sleep 0.1
}

pairing_from_table() {
  init_dialog "PIV Smart Card Pairing Tool" "Pairing..."
  # To make it a Jamf Pro script, comment out the following lines.
  source lookup_table/mapping-table.sh
  source lookup_table/pairing-from-table.sh $1 $2
  # To make it a Jamf Pro script, paste content of pairing-from-table.sh below.
}


PARAM1=$1
PARAM2=$2
if [ ${JAMF_PRO_MODE} -ne 0 ]; then
  PARAM1=$4
  PARAM2=$5
fi

case ${PARAM1} in
  pair)
    case ${PARAM2} in
      lookup_table)
        pairing_from_table ${LOGGEDIN_USER} ${DIALOG_CMD_FILE}
        ;;
      *)
        help
        quit 1
        ;;
    esac
    ;;
  unpair)
    unpair_piv
    ;;
  *)
    help
    quit 1
    ;;
esac

quit 0
