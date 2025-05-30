#!/bin/sh
set -e

PKG_DIR=/tmp
UPDATE_DIR=~/update

LOG_MSG="Checking /tmp for installable package"
logger  $LOG_MSG && echo $LOG_MSG
PKG_COUNT=$(ls $PKG_DIR/*.pkg 2>/dev/null | wc -l)

if [[ $PKG_COUNT -gt 1 || $PKG_COUNT  -eq 0 ]]; then
    logger  "Found $PKG_COUNT files in $PKG_DIR, exiting"
    exit 1
fi 

logger  "Making Update Directory $UPDATE_DIR"
mkdir -p $UPDATE_DIR


PKG_NAME=$(ls $PKG_DIR/*.pkg)
LOG_MSG="Found $PKG_NAME for update"
logger  $LOG_MSG && echo $LOG_MSG


xz -d -c $PKG_NAME | tar -xvf - -C "$UPDATE_DIR"
LOG_MSG="Decompressed $PKG_NAME"
logger  $LOG_MSG && echo $LOG_MSG

mv $UPDATE_DIR/*/* $UPDATE_DIR/
LOG_MSG="Moving Update Files Into Working Directory"
logger  $LOG_MSG && echo $LOG_MSG
. $UPDATE_DIR/updateFirmware.sh
if [[ $? -ne 0 ]]; then
    LOG_MSG="UPDATE FAILED, Check Previous System Logs For Details"
    logger  $LOG_MSG && echo $LOG_MSG
else
    rm -r $UPDATE_DIR
    LOG_MSG="UPDATE SUCCESSFUL, Rebooting Now"
    logger  $LOG_TAG && echo $LOG_MSG
fi
LOG_TAG=$_LOG_TAG
