#!/bin/bash
set -e

if [[ ! -f /UPDATE ]]; then
    logger "No Update was made, exiting"
    return 1
fi


# Determine which partition we are booted from
current_root=$(mount | awk '$3 == "/" {print $1}')
if [[ $current_root == "/dev/mmcblk0p2" ]]; then
    current_boot="a"
    inactive_boot="b"
    boot_partition="1"
    root_partition="2"
    inactive_boot_partition="3"
    inactive_root_partition="4"
elif [[ $current_root == "/dev/mmcblk0p4" ]]; then
    current_boot="b"
    inactive_boot="a"
    boot_partition="3"
    root_partition="4"
    inactive_boot_partition="1"
    inactive_root_partition="2"
else
    logger "Unknown root partition: $current_root"
    return 1
fi
logger "Found Active boot/root = $boot_partition/$root_partition"

logger "Resizing Filesystem"
resize2fs $current_root

logger -p 0 "Setting autoboot.txt For successful Update"
mount_point=/boot
mount /dev/mmcblk0p1 $mount_point
if [[ $inactive_boot == "a" ]]; then
    cat << EOF > $mount_point/autoboot.txt
    [all]
    tryboot_a_b=1
    boot_partition=3
    [tryboot]
    boot_partition=1
EOF
elif [[ $inactive_boot == "b" ]]; then
cat << EOF > $mount_point/autoboot.txt
    [all]
    tryboot_a_b=1
    boot_partition=1
    [tryboot]
    boot_partition=3
EOF
fi

umount $mount_point

set +e



