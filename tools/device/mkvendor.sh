#!/bin/bash

function usage
{
    echo Usage:
    echo "  $(basename $0) manufacturer device [boot.img]"
    echo "  The boot.img argument is the extracted recovery or boot image."
    echo "  The boot.img argument should not be provided for devices"
    echo "  that have non standard boot images (ie, Samsung)."
    echo
    echo Example:
    echo "  $(basename $0) motorola sholes ~/Downloads/recovery-sholes.img"
    exit 0
}

MANUFACTURER=$1
DEVICE=$2
BOOTIMAGE=$3

UNPACKBOOTIMG=$(which unpackbootimg)

echo Arguments: $@

if [ -z "$MANUFACTURER" ]
then
    usage
fi

if [ -z "$DEVICE" ]
then
    usage
fi

ANDROID_TOP=$(dirname $0)/../../../
pushd $ANDROID_TOP > /dev/null
ANDROID_TOP=$(pwd)
popd > /dev/null

TEMPLATE_DIR=$(dirname $0)
pushd $TEMPLATE_DIR > /dev/null
TEMPLATE_DIR=$(pwd)
popd > /dev/null

DEVICE_DIR=$ANDROID_TOP/device/$MANUFACTURER/$DEVICE

if [ ! -z "$BOOTIMAGE" ]
then
    if [ -z "$UNPACKBOOTIMG" ]
    then
        echo unpackbootimg not found. Is your android build environment set up and have the host tools been built?
        exit 0
    fi

    BOOTIMAGEFILE=$(basename $BOOTIMAGE)

    echo Output will be in $DEVICE_DIR
    mkdir -p $DEVICE_DIR

    TMPDIR=/tmp/$(whoami)/bootimg
    rm -rf $TMPDIR
    mkdir -p $TMPDIR
    cp $BOOTIMAGE $TMPDIR
    pushd $TMPDIR > /dev/null
    unpackbootimg -i $BOOTIMAGEFILE > /dev/null
    mkdir ramdisk
    pushd ramdisk > /dev/null
    gunzip -c ../$BOOTIMAGEFILE-ramdisk.gz | cpio -i
    popd > /dev/null
    BASE=$(cat $TMPDIR/$BOOTIMAGEFILE-base)
    CMDLINE=$(cat $TMPDIR/$BOOTIMAGEFILE-cmdline)
    PAGESIZE=$(cat $TMPDIR/$BOOTIMAGEFILE-pagesize)
    export SEDCMD="s#__CMDLINE__#$CMDLINE#g"
    echo $SEDCMD > $TMPDIR/sedcommand
    cp $TMPDIR/$BOOTIMAGEFILE-zImage $DEVICE_DIR/kernel
    popd > /dev/null
else
    mkdir -p $DEVICE_DIR
    touch $DEVICE_DIR/kernel
    BASE=10000000
    CMDLINE=no_console_suspend
    PAGESIZE=00000800
    export SEDCMD="s#__CMDLINE__#$CMDLINE#g"
    echo $SEDCMD > $TMPDIR/sedcommand
fi

for file in $(find $TEMPLATE_DIR -name '*.template')
do
    OUTPUT_FILE=$DEVICE_DIR/$(basename $(echo $file | sed s/\\.template//g))
    cat $file | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g | sed -f $TMPDIR/sedcommand | sed s/__BASE__/$BASE/g | sed s/__PAGE_SIZE__/$PAGESIZE/g > $OUTPUT_FILE
done

if [ ! -z "$TMPDIR" ]
then
    RECOVERY_FSTAB=$TMPDIR/ramdisk/etc/recovery.fstab
    if [ -f "$RECOVERY_FSTAB" ]
    then
        cp $RECOVERY_FSTAB $DEVICE_DIR/recovery.fstab
    fi
    if [ -f "$TMPDIR/ramdisk/sbin/htcbatt" ]
    then
        mkdir -p $DEVICE_DIR/recovery/root/sbin
        CHARGER_FILES="/sbin/choice_fn /sbin/htcbatt /sbin/power_test /sbin/offmode_charging /sbin/detect_key"
        for f in $CHARGER_FILES
        do
            if [ -f "$TMPDIR/ramdisk/$f" ]
            then
                cp $TMPDIR/ramdisk/$f $DEVICE_DIR/recovery/root/sbin
            fi
        done
        cp $TEMPLATE_DIR/init.htc.rc $DEVICE_DIR/recovery/root/init.$DEVICE.rc
    fi
fi


mv $DEVICE_DIR/device.mk $DEVICE_DIR/device_$DEVICE.mk

echo Creating initial git repository.
pushd $DEVICE_DIR
git init
git add .
git commit -a -m "mkvendor.sh: Initial commit of $DEVICE"
popd

echo Done!
echo Use the following command to set up your build environment:
echo '  'lunch cm_$DEVICE-eng
echo And use the follwowing command to build a recovery:
echo '  '. build/tools/device/makerecoveries.sh cm_$DEVICE-eng
