#!/bin/bash
clear
echo Installing Dependencies in 5 Seconds...
sleep 1
echo Installing Dependencies in 4 Seconds...
sleep 1
echo Installing Dependencies in 3 Seconds...
sleep 1
echo Installing Dependencies in 2 Seconds...
sleep 1
echo Installing Dependencies in 1 Seconds...
sleep 1
sudo apt-get update
sudo apt-get install openjdk-7-jdk
y
sudo apt-get update && sudo apt-get install git-core gnupg flex bison gperf libsdl1.2-dev libesd0-dev libwxgtk2.8-dev squashfs-tools build-essential zip curl libncurses5-dev zlib1g-dev openjdk-6-jre openjdk-6-jdk pngcrush schedtool libxml2 libxml2-utils xsltproc lzop libc6-dev schedtool g++-multilib lib32z1-dev lib32ncurses5-dev lib32readline-gplv2-dev gcc-multilib
y
echo Initializing REPO...
sleep 3
mkdir ~/bin
PATH=~/bin:$PATH
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
echo Creating RR Source Folder...
sleep 4
mkdir ~/rr
cd ~/rr
repo init -u https://github.com/ResurrectionRemix/platform_manifest.git -b lollipop
echo Syncing in 5 seconds...
sleep 1
echo Syncing in 4 seconds...
sleep 1
echo Syncing in 3 Seconds...
sleep 1
echo Syncing in 2 Seconds...
sleep 1
echo Syncing in 1 Seconds...
repo sync -j 16
clear
echo Setup is now Complete.