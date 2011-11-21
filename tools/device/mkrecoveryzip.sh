#!/bin/bash

OUT=$1
SIGNAPK=$2

if [ -z "$OUT" -o -z "$SIGNAPK" ]
then
    echo "Android build environment not detected."
    exit 1
fi

ANDROID_ROOT=$(pwd)
OUT=$ANDROID_ROOT/$OUT
SIGNAPK=$ANDROID_ROOT/$SIGNAPK

pushd . > /dev/null 2> /dev/null

UTILITIES_DIR=$OUT/utilities
mkdir -p $UTILITIES_DIR
RECOVERY_DIR=$UTILITIES_DIR/recovery
rm -rf $RECOVERY_DIR
mkdir -p $RECOVERY_DIR
cd $RECOVERY_DIR
cp -R $OUT/recovery/root/etc etc
cp -R $OUT/recovery/root/sbin sbin
cp -R $OUT/recovery/root/res res
SCRIPT_DIR=META-INF/com/google/android
mkdir -p $SCRIPT_DIR
cp $OUT/system/bin/updater $SCRIPT_DIR/update-binary


UPDATER_SCRIPT=$SCRIPT_DIR/updater-script
rm -f $UPDATER_SCRIPT
touch $UPDATER_SCRIPT
mkdir -p $(dirname $UPDATER_SCRIPT)

FILES=
SYMLINKS=

for file in $(find .)
do

if [ -d $file ]
then
  continue
fi

META_INF=$(echo $file | grep META-INF)
if [ ! -z $META_INF ]
then
    continue;
fi

if [ -h $file ]
then
    SYMLINKS=$SYMLINKS' '$file
elif [ -f $file ]
then
    FILES=$FILES' '$file
fi
done


echo 'ui_print("Replacing stock recovery with ClockworkMod recovery...");' >> $UPDATER_SCRIPT

echo 'delete("sbin/recovery");' >> $UPDATER_SCRIPT
echo 'package_extract_file("sbin/recovery", "/sbin/recovery");' >> $UPDATER_SCRIPT
echo 'set_perm(0, 0, 0755, "/sbin/recovery");' >> $UPDATER_SCRIPT
echo 'symlink("recovery", "/sbin/busybox");' >> $UPDATER_SCRIPT

echo 'run_program("/sbin/busybox", "sh", "-c", "busybox rm -f /etc ; busybox mkdir -p /etc;");' >> $UPDATER_SCRIPT

for file in $FILES
do
    echo 'delete("'$(echo $file | sed s!\\./!!g)'");' >> $UPDATER_SCRIPT
    echo 'package_extract_file("'$(echo $file | sed s!\\./!!g)'", "'$(echo $file | sed s!\\./!/!g)'");' >> $UPDATER_SCRIPT
    if [ -x $file ]
    then
        echo 'set_perm(0, 0, 0755, "'$(echo $file | sed s!\\./!/!g)'");' >> $UPDATER_SCRIPT
    fi
done
    
for file in $SYMLINKS
do
    echo 'symlink("'$(readlink $file)'", "'$(echo $file | sed s!\\./!/!g)'");' >> $UPDATER_SCRIPT
done

echo 'set_perm_recursive(0, 2000, 0755, 0755, "/sbin");' >> $UPDATER_SCRIPT
echo 'run_program("/sbin/busybox", "sh", "-c", "/sbin/killrecovery.sh");' >> $UPDATER_SCRIPT
rm -f $UTILITIES_DIR/unsigned.zip
rm -f $UTILITIES_DIR/update.zip
echo zip -ry $UTILITIES_DIR/unsigned.zip . -x $SYMLINKS '*\[*' '*\[\[*'
zip -ry $UTILITIES_DIR/unsigned.zip . -x $SYMLINKS '*\[*' '*\[\[*'
java -jar $SIGNAPK -w $ANDROID_ROOT/build/target/product/security/testkey.x509.pem $ANDROID_ROOT/build/target/product/security/testkey.pk8 $UTILITIES_DIR/unsigned.zip $UTILITIES_DIR/update.zip

echo Recovery FakeFlash is now available at $OUT/utilities/update.zip
popd > /dev/null 2> /dev/null
