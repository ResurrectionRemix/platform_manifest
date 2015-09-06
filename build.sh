#! /bin/bash

# The Build script to Compile Resurrection Remix


# No scrollback buffer
echo -e '\0033\0143'



# Obtain intial time of script startup
res1=$(date +%s.%N)



# Specify colors utilized in the terminal
red='tput setaf 1'              # red
green='tput setaf 2'            # green
yellow='tput setaf 3'           # yellow
blue='tput setaf 4'             # blue
violet='tput setaf 5'           # violet
cyan='tput setaf 6'             # cyan
white='tput setaf 7'            # white
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) # Bold red
bldgrn=${txtbld}$(tput setaf 2) # Bold green
bldblu=${txtbld}$(tput setaf 4) # Bold blue
bldcya=${txtbld}$(tput setaf 6) # Bold cyan
normal='tput sgr0'


tput bold
tput setaf 1
clear
echo -e ""
echo -e ""
echo -e "      (         (           (    (                       (        )      )  "
echo -e "      )\ )      )\ )        )\ ) )\ )        (     *   ) )\ )  ( /(   ( /(  "
echo -e "     (()/( (   (()/(    (  (()/((()/( (      )\    )  /((()/(  )\())  )\()) "
echo -e "      /(_)))\   /(_))   )\  /(_))/(_)))\   (((_)  ( )(_))/(_))((_)\  ((_)\  "
echo -e "     (_)) ((_) (_))  _ ((_)(_)) (_)) ((_)  )\___ (_(_())(_))    ((_)  _((_) "
echo -e "     | _ \| __|/ __|| | | || _ \| _ \| __|((/ __||_   _||_ _|  / _ \ | \| | "
echo -e "     |   /| _| \__ \| |_| ||   /|   /| _|  | (__   | |   | |  | (_) || .  | "
echo -e "     |_|_\|___||___/ \___/ |_|_\|_|_\|___|  \___|  |_|  |___|  \___/ |_|\_| "
echo -e ""
echo -e ""
echo -e "                         (           *     (        )                       "
echo -e "                         )\ )      (       )\ )  ( /(                       "
echo -e "                        (()/( (    )\))(  (()/(  )\())                      "
echo -e "                         /(_)))\  ((_)()\  /(_))((_)\                       "
echo -e "                        (_)) ((_) (_()((_)(_))  __((_)                      "
echo -e "                        | _ \| __||  \/  ||_ _| \ \/ /                      "
echo -e "                        |   /| _| | |\/| | | |   >  <                       "
echo -e "                        |_|_\|___||_|  |_||___| /_/\_\                      "
echo -e ""
echo -e ""
echo -e ""
echo -e ""
sleep 5
clear
echo -e ""
echo -e ""
echo -e "${bldgrn}  Setting up build environment..."
echo -e ""
echo -e ""
. build/envsetup.sh
echo -e "Build environment has been set up"
sleep 5
# Clear terminal
clear
# Confirm utilizing the 'make clean' function
echo -e "\n\n${bldgrn}  Do you want make clean or dirty or none?"
echo ""
echo -e "${bldblu}  1. clean"
echo -e "${bldblu}  2. dirty"
echo -e "${bldblu}  3. nothing"
echo ""
echo ""
$normal
read askclean
if [ "$askclean" == "1" ];
then
	echo ""
	echo ""
        echo -e "${bldgrn}  Removing files compiled from previous compilations - Cleaning... "
	echo ""
	echo ""
	$normal
        mka clean
elif [ "$askclean" == "2" ];
then
	echo "";echo "";echo -e "${bldgrn} Making dirty";echo "";echo "";
	mka dirty
else
	echo -e ""
	echo -e ""
	echo -e "Continuing compilation of Resurrection Remix without deleting old build files"
	echo -e ""
	echo -e ""
fi
sleep 5
# Clear terminal
clear
# Lunch device
echo -e ""
echo -e ""
echo -e "${bldcya}  Choose your device from the lunch menu..."
echo -e ""
echo -e ""
$normal
$green
sleep 5
lunch
sleep 5
clear
# Start compilation
echo -e ""
echo -e ""
echo -e "${bldcya}  Starting compilation of Resurrection Remix..."
echo -e ""
echo -e ""
echo -e "Enter the number of threads you want to use for compilation"
echo -e "If you unsure on what to select, enter 0";
$normal
read threads
if [ "$threads" == "0" ]
then
time mka bacon
else
time make -j$threads
fi
echo -e ""
# Get elapsed time
$blue
res2=$(date +%s.%N)
echo -e ""
echo -e ""
echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"
echo -e ""
echo -e ""


# Compilation complete
tput bold
tput setaf 1
clear
echo -e " "
echo -e "█████████████████████████████████████████████████████████████"
echo -e "█░░░░░░██░░░░░░█░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░░░░░█"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░█████████"
echo -e "█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█"
echo -e "█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█"
echo -e "█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀░░▄▀▄▀░░█░░▄▀░░█████████"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░░░▄▀▄▀▄▀░░░░█░░▄▀░░░░░░░░░░█"
echo -e "█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░███░░░░▄▀░░░░███░░▄▀▄▀▄▀▄▀▄▀░░█"
echo -e "█░░░░░░██░░░░░░█░░░░░░██░░░░░░█████░░░░░░█████░░░░░░░░░░░░░░█"
echo -e "█████████████████████████████████████████████████████████████"
echo -e "█████████████████████████████████████████████████████████████"
echo -e "█░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░██████████░░░░░░█░░░░░░█"
echo -e "█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░██░░▄▀░░█░░▄▀░░█"
echo -e "█░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░██░░▄▀░░█░░▄▀░░█"
echo -e "█░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░██░░▄▀░░█░░▄▀░░█"
echo -e "█░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░█"
echo -e "█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░█"
echo -e "█░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░░░░░█"
echo -e "█░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░░░░░▄▀░░████████"
echo -e "█░░▄▀░░█████████░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀▄▀▄▀▄▀▄▀░░█░░░░░░█"
echo -e "█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░░░░░░░░░▄▀░░█░░▄▀░░█"
echo -e "█░░░░░░█████████░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█░░░░░░█"
echo -e "█████████████████████████████████████████████████████████████"
echo -e " "
echo -e " Compilation Completed! Congratulations on the succesful build!"

EXPORT_CCACHE=1

# Switch terminal back to normal
$normal
