#!/bin/sh

logger -p 1 "Checking for update TAG in filesystem"
if [[ -f /UPDATE ]]; then
    . /obsc/scripts/verifyUpdate.sh
else
    logger -p 1 "No Update was detected. Moving on."
fi

logger -p 4 "Fetching Config Files"
source /obsc/scripts/default.conf
source /obsc/config/mod.conf


logger -p 4 "Setting CPU Governer to Performance Mode"
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

logger -p 4 "Setting Hostname"
hostnamectl set-hostname $OBSC_SYSTEM_NAME




logger -p 0 "Finished startup, system has been configured"