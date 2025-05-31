#!/bin/sh
set -e


CONFIGURATION_DIR=/obsc/config
SSH_DIR=/etc/ssh
JOURNAL_DIR=/var/log/journal
LOGIN_FILES="/etc/passwd /etc/shadow /etc/group"

logger "Checking current boot partition"
# Determine which partition we are booted from
CURRENT_ROOT=$(mount | awk '$3 == "/" {print $1}')
if [[ $CURRENT_ROOT == "/dev/mmcblk0p2" ]]; then
    INACTIVE_BOOT="b"
    boot_partition="1"
    root_partition="2"
    INACTIVE_BOOT_PARTITION="3"
    INACTIVE_ROOT_PARTITION="4"
elif [[ $CURRENT_ROOT == "/dev/mmcblk0p4" ]]; then
    INACTIVE_BOOT="a"
    boot_partition="3"
    root_partition="4"
    INACTIVE_BOOT_PARTITION="1"
    INACTIVE_ROOT_PARTITION="2"
else
    logger "Uknown root partition $CURRENT_ROOT"
    echo "Unknown root partition: $CURRENT_ROOT"
    return 1
fi
logger  "Found current boot/root: $boot_partition/$root_partition"
MOUNT_POINT=/tmp/boot
mkdir $MOUNT_POINT


if [[ ! -f $UPDATE_DIR/boot_update.vfat || ! -f $UPDATE_DIR/root_a.ext4 ]]; then
    LOG_MSG="Missing Correct Update Files"
    logger  && echo $LOG_MSG
    exit 1
fi
LOG_MSG="Writing Firmware to Flash"
logger  $LOG_MSG && echo $LOG_MSG
dd if=$UPDATE_DIR/boot_update.vfat of=/dev/mmcblk0p$INACTIVE_BOOT_PARTITION
dd if=$UPDATE_DIR/root_a.ext4 of=/dev/mmcblk0p$INACTIVE_ROOT_PARTITION

LOG_MSG="Tagging Update Filesystem"
echo $LOG_MSG && logger  $LOG_MSG
mount /dev/mmcblk0p$INACTIVE_ROOT_PARTITION $MOUNT_POINT
touch $MOUNT_POINT/UPDATE
LOG_MSG="Copying configuration, log, and ssh files to new firmware"
echo $LOG_MSG && logger  $LOG_MSG
mkdir -p $MOUNT_POINT$CONFIGURATION_DIR
cp -rf $CONFIGURATION_DIR/* $MOUNT_POINT$CONFIGURATION_DIR
cp -f $SSH_DIR/*_key* $MOUNT_POINT$SSH_DIR
# Copy login files
for file in $LOGIN_FILES; do
    rm $MOUNT_POINT$file
    cp -f $file $MOUNT_POINT$file
done

umount $MOUNT_POINT
LOG_MSG="Unmounted new filesystem"
echo $LOG_MSG && logger  $LOG_MSG


LOG_MSG="Mounting inactive boot, and creating cmdline.txt"
echo $LOG_MSG && logger  $LOG_MSG
mount /dev/mmcblk0p$INACTIVE_BOOT_PARTITION $MOUNT_POINT
if [[ $INACTIVE_BOOT == "a" ]]; then
    echo "root=/dev/mmcblk0p2 rootwait console=tty1 pci=nomsi" > $MOUNT_POINT/cmdline.txt
    cat <<EOL > $MOUNT_POINT/autoboot.txt
    [all]
    tryboot_a_b=1
    boot_partition=3
    [tryboot]
    boot_partition=1
EOL
elif [[ $INACTIVE_BOOT == "b" ]]; then
    echo "root=/dev/mmcblk0p4 rootwait console=tty1 pci=nomsi" > $MOUNT_POINT/cmdline.txt
fi
umount $MOUNT_POINT
LOG_MSG="Finished with cmdline.txt, rebooting next"
echo $LOG_MSG && logger $LOG_MSG
set +e