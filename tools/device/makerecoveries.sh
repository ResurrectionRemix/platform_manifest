if [ -z "$1" ]
then
    echo "Please provide a lunch option."
    return 1
fi

PRODUCTS=$1

for product in $PRODUCTS
do
    echo $product
done

echo $(echo $PRODUCTS | wc -w) Products

unset PUBLISHED_RECOVERIES

MCP=$(which mcp)
if [ -z "$MCP" ]
then
    NO_UPLOAD=true
fi

function mcpguard () {
    if [ -z "$NO_UPLOAD" ]
    then
        mcp $1 $2
        md5sum $1 > $1.md5sum.txt
        mcp $1.md5sum.txt $2.md5sum.txt
    fi
}

VERSION=$(cat bootable/recovery/Android.mk | grep RECOVERY_VERSION | grep RECOVERY_NAME | awk '{ print $4 }' | sed s/v//g)
RELEASE_VERSION=$VERSION
if [ ! -z "$BOARD_TOUCH_RECOVERY" ]
then
    RELEASE_VERSION=touch-$VERSION
fi

echo Recovery Version: $RELEASE_VERSION

for lunchoption in $PRODUCTS
do
    lunch $lunchoption
    RESULT=$?
    if [ "$RESULT" != "0" ]
    then
        echo build error!
        return 1
    fi
    if [ -z "$NO_CLEAN" ]
    then
        rm -rf $OUT/obj/EXECUTABLES/recovery_intermediates
        rm -rf $OUT/recovery*
        rm -rf $OUT/root*
    fi
    DEVICE_NAME=$(echo $TARGET_PRODUCT | sed s/koush_// | sed s/zte_// | sed s/cm_// | sed s/aosp_// |  sed s/motorola// | sed s/huawei_// | sed s/htc_// | sed s/_us// | sed s/cyanogen_// | sed s/generic_// | sed s/full_//)
    PRODUCT_NAME=$(basename $OUT)
    make -j16 recoveryzip
    RESULT=$?
    if [ "$RESULT" != "0" ]
    then
        echo build error!
        return 1
    fi
    mcpguard $OUT/recovery.img recoveries/recovery-clockwork-$RELEASE_VERSION-$DEVICE_NAME.img
    mcpguard $OUT/utilities/update.zip recoveries/recovery-clockwork-$RELEASE_VERSION-$DEVICE_NAME.zip
    
    if [ -f "ROMManagerManifest/devices.rb" ]
    then
        pushd ROMManagerManifest
        ruby devices.rb $DEVICE_NAME $VERSION $lunchoption
        popd
    fi
done

for published_recovery in $PUBLISHED_RECOVERIES
do
    echo $published_recovery
done

