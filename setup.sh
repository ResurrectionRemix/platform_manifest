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
clear
echo Dependencies have been installed!
sleep 4
clear
echo Installing REPO in 5 Seconds...
sleep 1
echo Installing REPO in 4 Seconds...
sleep 1
echo Installing REPO in 3 Seconds...
sleep 1
echo Installing REPO in 2 Seconds...
sleep 1
echo Installing REPO in 1 Seconds...
sleep 1
mkdir ~/bin
PATH=~/bin:$PATH
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
clear
echo REPO has been Downloaded!
sleep 3
clear
echo Where do you want to initialize RR source? Enter the desired directory name similar to this:
echo " /home/$USER/rr or /media/$user/yourdrive/rr"
read rrpath
clear
sleep 2
echo Creating and Initializing RR Source at $rrpath in 5...
sleep 1
echo Creating and Initializing RR Source at $rrpath in 4...
sleep 1
echo Creating and Initializing RR Source at $rrpath in 3...
sleep 1
echo Creating and Initializing RR Source at $rrpath in 2...
sleep 1
echo Creating and Initializing RR Source at $rrpath in 1...
sleep 1
mkdir -p $rrpath
cd $rrpath
repo init -u https://github.com/ResurrectionRemix/platform_manifest.git -b lollipop
clear
echo Unpacking all Resurrection Remix Resources...
mv $rrpath/android_build/build_device.sh $rrpath/build_device.sh
chmod a+x $rrpath/build_device.sh
echo RR Source Code has been initialized!
sleep 4
clear
echo Enter 1 to repo sync now, anything else to do it later
read ch
if [ $ch -eq 1 ] ; then
        echo Enter number of jobs to repo sync with. If you are not sure, enter 4
        read jobs
        echo Syncing/Downloading in 5 seconds...
        sleep 1
        echo Syncing/Downloading in 4 seconds...
        sleep 1
        echo Syncing/Downloading in 3 Seconds...
        sleep 1
        echo Syncing/Downloading in 2 Seconds...
        sleep 1
        echo Syncing/Downloading in 1 Seconds...
        repo sync -j $jobs
clear
echo Resurrection Remix Source code has been Set-Up Succesfully.
else
        echo Repo has been initialized in $rrpath
        echo To sync the source again, cd to $rrpath and run the following command
        echo "repo sync"
        echo To build Resurrection Remix, initialize the RR Build Wizard by typing:
        echo "./build_device.sh"
fi

