#!/bin/sh
OS_DIR=`pwd`
BUILDROOT=$OS_DIR/buildroot


#VERSION INFO
MAJOR_VERSION="0"
MINOR_VERSION="0"
PATCH_VERSION="1"
WORKING_COMMIT=$(git rev-parse --short HEAD)
VERSION=$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION
COMMIT_VERSION=$VERSION.$WORKING_COMMIT
echo "BUILDING: $VERSION"

#Overlay directories.
ROOT=$OS_DIR/root_overlay
DYNAMIC=$OS_DIR/dynamic
BOOT=$OS_DIR/boot_overlay
OUTPUT=$OS_DIR/output
CONFIG_DIR=$OS_DIR/config


VFATFS=$BUILDROOT/output/images/boot.vfat
EXTFS=$BUILDROOT/output/images/rootfs.ext4

#Config/Update Files
GENIMAGE_CFG=$CONFIG_DIR/genimage.cfg
UPDATE=$CONFIG_DIR/updateFirmware.sh

#Dynamic Directories
DY_UTILS=$DYNAMIC/obsc/utils/

#------------------------------------------------------------------------------------------------------------------------

# Check if the build output version file exists
if [ ! -f "$OUTPUT/$VERSION" ]; then
    echo "BUILDROOT WILL BUILD FROM SCRATCH"
    sudo ls .
    cp $CONFIG_DIR/pi_stock_genimage.cfg.in  $BUILDROOT/board/raspberrypi/genimage.cfg.in
    cp "$CONFIG_DIR/BUILDROOT.cfg" "$BUILDROOT/.config"
    cp "$CONFIG_DIR/linux.config" $BUILDROOT/
    # BUILDROOT
    echo "Building Base Buildroot System"
    cd buildroot && . utils/add-custom-hashes
    cd ..
    make -C "$BUILDROOT"
    echo "Finished building base system, gathering compiled packages"
    #Copy Compiled Filesystem
    # Create the version file to indicate the build is done
    touch "$OUTPUT/$VERSION"
else
    echo "Buildroot system for version $VERSION already exists. Skipping build."
fi

echo "DO NOT RUN AS SUDO, SCRIPT SHOULD REQUEST SUDO PERMISSIONS WHEN NEEDED"

echo "Getting first Sudo permission"
sudo ls .

#------------------------------------------------------------------------------------------------------------------------
# Get the boot/root files from buildroot

LINUX_SRC=$BUILDROOT/output/build/linux-custom
sudo cp -f $VFATFS "$OUTPUT/$VERSION.boot_a.vfat"
sudo cp -f $VFATFS $OUTPUT/$VERSION.boot_b.vfat
sudo cp -f $VFATFS $OUTPUT/$VERSION.boot_update.vfat
sudo cp -f $EXTFS $OUTPUT/$VERSION.root.ext4

#------------------------------------------------------------------------------------------------------------------------

#Build Dynamic Directories
mkdir -p $DY_UTILS

#------------------------------------------------------------------------------------------------------------------------

cat > "$DY_UTILS/version.conf" <<- EOM
MAJOR_VERSION="$MAJOR_VERSION"
MINOR_VERSION="$MINOR_VERSION"
PATCH_VERSION="$PATCH_VERSION"
COMMIT_VERSION="$COMMIT_VERSION"
EOM


#------------------------------------------------------------------------------------------------------------------------

#Work on the root filesystem.
echo "MODIFYING ROOT FILESYSTEM"

ROOT_FILES=$OUTPUT/root
mkdir -p $ROOT_FILES
sudo cp $OUTPUT/$VERSION.root.ext4 $OUTPUT/root_a.ext4
sudo mount -o loop $OUTPUT/$VERSION.root.ext4 $ROOT_FILES
sudo touch $ROOT_FILES/$COMMIT_VERSION
sudo touch $ROOT_FILES/UPDATE
sudo mkdir -p $ROOT_FILES/var/lib/misc
sudo cp -rf $DYNAMIC/* $ROOT_FILES/
sudo cp -rf $ROOT/* $ROOT_FILES/
sudo umount $ROOT_FILES
sudo rm -r $ROOT_FILES
sudo cp $OUTPUT/$VERSION.root.ext4 $OUTPUT/root_a.ext4


#------------------------------------------------------------------------------------------------------------------------

#Make each of the boot files
echo "MODIFYING BOOT FILESYSTEM"

BOOT_A=$OUTPUT/boot_a
BOOT_B=$OUTPUT/boot_b
BOOT_UPDATE=$OUTPUT/boot_update

mkdir -p $BOOT_A
mkdir -p $BOOT_B
mkdir -p $BOOT_UPDATE



sudo mount -o loop $OUTPUT/$VERSION.boot_a.vfat  $BOOT_A
sudo mount -o loop $OUTPUT/$VERSION.boot_b.vfat  $BOOT_B
sudo mount -o loop $OUTPUT/$VERSION.boot_update.vfat  $BOOT_UPDATE

sudo rm $BOOT_UPDATE/cmdline.txt && sudo rm $BOOT_UPDATE/autoboot.txt && sudo rm $BOOT_UPDATE/config.txt
sudo rm $BOOT_A/cmdline.txt && sudo rm $BOOT_A/autoboot.txt && sudo rm $BOOT_A/config.txt
sudo rm $BOOT_B/cmdline.txt && sudo rm $BOOT_B/autoboot.txt && sudo rm $BOOT_B/config.txt


sudo cp $BOOT/cmdline_a.txt $BOOT_A/cmdline.txt && sudo cp $BOOT/cmdline_b.txt $BOOT_B/cmdline.txt
sudo cp $BOOT/config.txt $BOOT_UPDATE/ && sudo cp $BOOT/config.txt $BOOT_A/ && sudo cp $BOOT/config.txt $BOOT_B/
sudo cp $BOOT/autoboot.txt $BOOT_A/


sudo umount $BOOT_A
sudo umount $BOOT_B
sudo umount $BOOT_UPDATE
sudo rm -r $BOOT_A
sudo rm -r $BOOT_B
sudo rm -r $BOOT_UPDATE
sudo cp $OUTPUT/$VERSION.boot_a.vfat $OUTPUT/boot_a.vfat
sudo cp $OUTPUT/$VERSION.boot_b.vfat $OUTPUT/boot_b.vfat

#------------------------------------------------------------------------------------------------------------------------

#Make Update File
echo "CREATING UPDATE PACKAGE"
mkdir $OUTPUT/$COMMIT_VERSION
cp $OUTPUT/$VERSION.boot_update.vfat $OUTPUT/$COMMIT_VERSION/boot_update.vfat
cp $OUTPUT/root_a.ext4 $OUTPUT/$COMMIT_VERSION/
cp $UPDATE $OUTPUT/$COMMIT_VERSION/

echo "Zipping Update Directory"
tar -cf - -C $OUTPUT $COMMIT_VERSION/ | xz -9 -e -T0 -c > $OUTPUT/$COMMIT_VERSION.pkg


#------------------------------------------------------------------------------------------------------------------------

#Make Base Install Image
echo "GENERATING IMAGE"
sudo genimage \
    --config $GENIMAGE_CFG \
    --inputpath "${OUTPUT}" \
    --outputpath "${OUTPUT}"


mkdir -p $OUTPUT/$COMMIT_VERSION
zip -j "$OUTPUT/$COMMIT_VERSION/$COMMIT_VERSION.BASE_INSTALL.zip" "$OUTPUT/BASE_INSTALL.img"
mv $OUTPUT/$COMMIT_VERSION.pkg $OUTPUT/$COMMIT_VERSION

#------------------------------------------------------------------------------------------------------------------------


#CLEANUP
echo "CLEANING UP FILES"
sudo rm $OUTPUT/BASE_INSTALL.img
sudo rm -r $OUTPUT/boot_a.vfat
sudo rm -r $OUTPUT/boot_b.vfat
sudo rm -r $OUTPUT/root_a.ext4
sudo rm -r $OUTPUT/$VERSION.boot_a.vfat
sudo rm -r $OUTPUT/$VERSION.boot_b.vfat
sudo rm -r $OUTPUT/$VERSION.boot_update.vfat
sudo rm -r $OUTPUT/$VERSION.root.ext4
sudo rm -r *
git restore .
cd ..
sudo rm -r $DYNAMIC/*
echo $COMMIT_VERSION
