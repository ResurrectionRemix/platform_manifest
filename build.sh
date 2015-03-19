#!/bin/bash
clear
echo Welcome to the Resurrection Remix Build Wizard!
echo This Wizard will be helping you to build ROMs for your device from Resurrection Remix
echo Do note that for EVERYTHING you type, you are required to type in LOWER CASE
echo If they are not, you may expereince some errors along the way
sleep 10
echo Please hold while we set up the Build Environment...
sleep 3
. build/envsetup.sh
sleep 2
clear
echo Before we begin, what Device manafacturer do you want to build for?
echo A device manafacturer is similar to sony, htc, samsung and etc
read creator
echo Downloading Vendor Source for $creator from TheMuppets in 5...
sleep 1
echo Downloading Vendor Source for $creator from TheMuppets in 4...
sleep 1
echo Downloading Vendor Source for $creator from TheMuppets in 3...
sleep 1
echo Downloading Vendor Source for $creator from TheMuppets in 2...
sleep 1
echo Downloading Vendor Source for $creator from TheMuppets in 1...
sleep 1
cd vendor 
    git clone https://github.com/TheMuppets/proprietary_vendor_$creator.git
    croot
    mv vendor/proprietary_vendor_$creator vendor/$creator
clear
echo Now please input the device codename you want to build:
echo A device codename is similar to the Xperia Z3 Codename from CyanogenMod, z3
echo Find your device codename here: http://wiki.cyanogenmod.org/w/Devices#vendor=;
read device
echo Downloading Device Source for $device in 5...
sleep 1
echo Downloading Device Source for $device in 4...
sleep 1
echo Downloading Device Source for $device in 3...
sleep 1
echo Downloading Device Source for $device in 2...
sleep 1
echo Downloading Device Source for $device in 1...
sleep 1
    breakfast $device
clear
    repo sync -j6
clear
echo Device Specific Source has been Downloaded and Ready to be utilized!
echo Do you want to build Resurrection Remix for $device now? Type 1 or 0 
read ch
if [ $ch -eq 1 ] ; then
        echo Building for $device in 5 seconds...
        sleep 1
        echo Building for $device in 4 seconds...
        sleep 1
        echo Building for $device in 3 seconds...
        sleep 1
        echo Building for $device in 2 seconds...
        sleep 1
        echo Building for $device in 1 seconds...
        brunch $device
clear
echo Resurrection Remix has been built succesfully! The ROM can be found in the out/product/$device folder!
echo Exiting the Resurrection Remix Build Wizard in 10 seconds!
echo To cancel, Press CTRL + C
    sleep 10
    exit
else
clear
        echo To build next time, cd to the RR directory
        echo and type the following command:
        echo                    
        echo brunch $device
        echo                     
        echo Or Alternatively, Run this Wizard again by typing;
        echo ./build_device.sh
sleep 3
    echo     
    echo     
                echo Exiting the Resurrection Remix Build Wizard in 10 seconds!
                echo To exit immediately, Press CTRL + C
                sleep 10
    exit
fi
