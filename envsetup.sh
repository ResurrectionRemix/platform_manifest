function hmm() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- lunch:   lunch <product_name>-<build_variant>
- tapas:   tapas [<App1> <App2> ...] [arm|x86|mips|armv5] [eng|userdebug|user]
- croot:   Changes directory to the top of the tree.
- cout:    Changes directory to out.
- m:       Makes from the top of the tree.
- mm:      Builds all of the modules in the current directory.
- mmp:     Builds all of the modules in the current directory and pushes them to the device.
- mmm:     Builds all of the modules in the supplied directories.
- mmmp:    Builds all of the modules in the supplied directories and pushes them to the device.
- mma:     Builds all of the modules in the current directory, and their dependencies.
- mmma:    Builds all of the modules in the supplied directories, and their dependencies.
- cgrep:   Greps on all local C/C++ files.
- jgrep:   Greps on all local Java files.
- resgrep: Greps on all local res/*.xml files.
- godir:   Go to the directory containing a file.
- cmremote: Add git remote for CM Gerrit Review.
- cmgerrit: A Git wrapper that fetches/pushes patch from/to CM Gerrit Review.
- cmrebase: Rebase a Gerrit change and push it again.
- aospremote: Add git remote for matching AOSP repository.
- cafremote: Add git remote for matching CodeAurora repository.
- mka:      Builds using SCHED_BATCH on all processors.
- mkap:     Builds the module(s) using mka and pushes them to the device.
- cmka:     Cleans and builds using mka.
- repolastsync: Prints date and time of last repo sync.
- reposync: Parallel repo sync using ionice and SCHED_BATCH.
- repopick: Utility to fetch changes from Gerrit.
- installboot: Installs a boot.img to the connected device.
- installrecovery: Installs a recovery.img to the connected device.

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^function /s/function \([a-z_]*\).*/\1/p" | sort`; do
      A="$A $i"
    done
    echo $A
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    (\cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-abs-$1)
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
}

# check to see if the supplied product is one we can build
function check_product()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    if (echo -n $1 | grep -q -e "^cm_") ; then
       CM_BUILD=$(echo -n $1 | sed -e 's/^cm_//g')
       export BUILD_NUMBER=$((date +%s%N ; echo $CM_BUILD; hostname) | openssl sha1 | sed -e 's/.*=//g; s/ //g' | cut -c1-10)
    else
       CM_BUILD=
    fi
    export CM_BUILD

    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        TARGET_PRODUCT=$1 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

VARIANT_CHOICES=(user userdebug eng)

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

function setpaths()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi

    ##################################################################
    #                                                                #
    #              Read me before you modify this code               #
    #                                                                #
    #   This function sets ANDROID_BUILD_PATHS to what it is adding  #
    #   to PATH, and the next time it is run, it removes that from   #
    #   PATH.  This is required so lunch can be run more than once   #
    #   and still have working paths.                                #
    #                                                                #
    ##################################################################

    # Note: on windows/cygwin, ANDROID_BUILD_PATHS will contain spaces
    # due to "C:\Program Files" being in the path.

    # out with the old
    if [ -n "$ANDROID_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_BUILD_PATHS/}
    fi
    if [ -n "$ANDROID_PRE_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_PRE_BUILD_PATHS/}
        # strip leading ':', if any
        export PATH=${PATH/:%/}
    fi

    # and in with the new
    CODE_REVIEWS=
    prebuiltdir=$(getprebuilt)
    gccprebuiltdir=$(get_abs_build_var ANDROID_GCC_PREBUILTS)

    # defined in core/config.mk
    targetgccversion=$(get_build_var TARGET_GCC_VERSION)
    export TARGET_GCC_VERSION=$targetgccversion

    # The gcc toolchain does not exists for windows/cygwin. In this case, do not reference it.
    export ANDROID_EABI_TOOLCHAIN=
    local ARCH=$(get_build_var TARGET_ARCH)
    case $ARCH in
        x86) toolchaindir=x86/i686-linux-android-$targetgccversion/bin
            ;;
        arm) toolchaindir=arm/linaro-4.7.4/bin
            ;;
        mips) toolchaindir=mips/mipsel-linux-android-$targetgccversion/bin
            ;;
        *)
            echo "Can't find toolchain for unknown architecture: $ARCH"
            toolchaindir=xxxxxxxxx
            ;;
    esac
    if [ -d "$gccprebuiltdir/$toolchaindir" ]; then
        export ANDROID_EABI_TOOLCHAIN=$gccprebuiltdir/$toolchaindir
    fi

    unset ARM_EABI_TOOLCHAIN ARM_EABI_TOOLCHAIN_PATH
    case $ARCH in
        arm)
            toolchaindir=arm/linaro-4.7.4/bin
            if [ -d "$gccprebuiltdir/$toolchaindir" ]; then
                 export ARM_EABI_TOOLCHAIN="$gccprebuiltdir/$toolchaindir"
                 ARM_EABI_TOOLCHAIN_PATH=":$gccprebuiltdir/$toolchaindir"
            fi
            ;;
        mips) toolchaindir=mips/mips-eabi-4.4.3/bin
            ;;
        *)
            # No need to set ARM_EABI_TOOLCHAIN for other ARCHs
            ;;
    esac

    export ANDROID_TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN
    export ANDROID_QTOOLS=$T/development/emulator/qtools
    export ANDROID_DEV_SCRIPTS=$T/development/scripts:$T/prebuilts/devtools/tools
    export ANDROID_BUILD_PATHS=$(get_build_var ANDROID_BUILD_PATHS):$ANDROID_QTOOLS:$ANDROID_TOOLCHAIN$ARM_EABI_TOOLCHAIN_PATH$CODE_REVIEWS:$ANDROID_DEV_SCRIPTS:
    export PATH=$ANDROID_BUILD_PATHS$PATH

    unset ANDROID_JAVA_TOOLCHAIN
    unset ANDROID_PRE_BUILD_PATHS
    if [ -n "$JAVA_HOME" ]; then
        export ANDROID_JAVA_TOOLCHAIN=$JAVA_HOME/bin
        export ANDROID_PRE_BUILD_PATHS=$ANDROID_JAVA_TOOLCHAIN:
        export PATH=$ANDROID_PRE_BUILD_PATHS$PATH
    fi

    unset ANDROID_PRODUCT_OUT
    export ANDROID_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
    export OUT=$ANDROID_PRODUCT_OUT

    unset ANDROID_HOST_OUT
    export ANDROID_HOST_OUT=$(get_abs_build_var HOST_OUT)

    # needed for processing samples collected by perf counters
    unset OPROFILE_EVENTS_DIR
    export OPROFILE_EVENTS_DIR=$T/external/oprofile/events

    # needed for building linux on MacOS
    # TODO: fix the path
    #export HOST_EXTRACFLAGS="-I "$T/system/kernel_headers/host_include
}

function printconfig()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    get_build_var report_config
}

function set_stuff_for_environment()
{
    settitle
    set_java_home
    setpaths
    set_sequence_number
}

function set_sequence_number()
{
    export BUILD_ENV_SEQUENCE_NUMBER=10
}

function settitle()
{
    if [ "$STAY_OFF_MY_LAWN" = "" ]; then
        local arch=$(gettargetarch)
        local product=$TARGET_PRODUCT
        local variant=$TARGET_BUILD_VARIANT
        local apps=$TARGET_BUILD_APPS
        if [ -z "$PROMPT_COMMAND"  ]; then
            # No prompts
            PROMPT_COMMAND="echo -ne \"\033]0;${USER}@${HOSTNAME}: ${PWD}\007\""
        elif [ -z "$(echo $PROMPT_COMMAND | grep '033]0;')" ]; then
            # Prompts exist, but no hardstatus
            PROMPT_COMMAND="echo -ne \"\033]0;${USER}@${HOSTNAME}: ${PWD}\007\";${PROMPT_COMMAND}"
        fi
        if [ ! -z "$ANDROID_PROMPT_PREFIX" ]; then
            PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed -e 's/$ANDROID_PROMPT_PREFIX //g')"
        fi

        if [ -z "$apps" ]; then
            ANDROID_PROMPT_PREFIX="[${arch}-${product}-${variant}]"
        else
            ANDROID_PROMPT_PREFIX="[$arch $apps $variant]"
        fi
        export ANDROID_PROMPT_PREFIX

        # Inject build data into hardstatus
        export PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed -e 's/\\033]0;\(.*\)\\007/\\033]0;$ANDROID_PROMPT_PREFIX \1\\007/g')"
    fi
}

function check_bash_version()
{
    # Keep us from trying to run in something that isn't bash.
    if [ -z "${BASH_VERSION}" ]; then
        return 1
    fi

    # Keep us from trying to run in bash that's too old.
    if [ "${BASH_VERSINFO[0]}" -lt 4 ] ; then
        return 2
    fi

    return 0
}

function choosetype()
{
    echo "Build type choices are:"
    echo "     1. release"
    echo "     2. debug"
    echo

    local DEFAULT_NUM DEFAULT_VALUE
    DEFAULT_NUM=1
    DEFAULT_VALUE=release

    export TARGET_BUILD_TYPE=
    local ANSWER
    while [ -z $TARGET_BUILD_TYPE ]
    do
        echo -n "Which would you like? ["$DEFAULT_NUM"] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi
        case $ANSWER in
        "")
            export TARGET_BUILD_TYPE=$DEFAULT_VALUE
            ;;
        1)
            export TARGET_BUILD_TYPE=release
            ;;
        release)
            export TARGET_BUILD_TYPE=release
            ;;
        2)
            export TARGET_BUILD_TYPE=debug
            ;;
        debug)
            export TARGET_BUILD_TYPE=debug
            ;;
        *)
            echo
            echo "I didn't understand your response.  Please try again."
            echo
            ;;
        esac
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

#
# This function isn't really right:  It chooses a TARGET_PRODUCT
# based on the list of boards.  Usually, that gets you something
# that kinda works with a generic product, but really, you should
# pick a product by name.
#
function chooseproduct()
{
    if [ "x$TARGET_PRODUCT" != x ] ; then
        default_value=$TARGET_PRODUCT
    else
        default_value=full
    fi

    export TARGET_PRODUCT=
    local ANSWER
    while [ -z "$TARGET_PRODUCT" ]
    do
        echo -n "Which product would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_PRODUCT=$default_value
        else
            if check_product $ANSWER
            then
                export TARGET_PRODUCT=$ANSWER
            else
                echo "** Not a valid product: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

function choosevariant()
{
    echo "Variant choices are:"
    local index=1
    local v
    for v in ${VARIANT_CHOICES[@]}
    do
        # The product name is the name of the directory containing
        # the makefile we found, above.
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=eng
    local ANSWER

    export TARGET_BUILD_VARIANT=
    while [ -z "$TARGET_BUILD_VARIANT" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_BUILD_VARIANT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#VARIANT_CHOICES[@]}" ] ; then
                export TARGET_BUILD_VARIANT=${VARIANT_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_variant $ANSWER
            then
                export TARGET_BUILD_VARIANT=$ANSWER
            else
                echo "** Not a valid variant: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done
}

function choosecombo()
{
    choosetype $1

    echo
    echo
    chooseproduct $2

    echo
    echo
    choosevariant $3

    echo
    set_stuff_for_environment
    printconfig
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# add the default one here
add_lunch_combo aosp_arm-eng
add_lunch_combo aosp_x86-eng
add_lunch_combo aosp_mips-eng
add_lunch_combo vbox_x86-eng

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    if [ "$(uname)" = "Darwin" ] ; then
       echo "  (ohai, koush!)"
    fi
    echo
    if [ "z${CM_DEVICES_ONLY}" != "z" ]; then
       echo "Breakfast menu... pick a combo:"
    else
       echo "Lunch menu... pick a combo:"
    fi

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]}
    do
        echo " $i. $choice "
        i=$(($i+1))
    done | column

    if [ "z${CM_DEVICES_ONLY}" != "z" ]; then
       echo "... and don't forget the bacon!"
    fi

    echo
}

function brunch()
{
    breakfast $*
    if [ $? -eq 0 ]; then
        mka bacon
    else
        echo "No such item in brunch menu. Try 'breakfast'"
        return 1
    fi
    return $?
}

function breakfast()
{
    target=$1
    CM_DEVICES_ONLY="true"
    unset LUNCH_MENU_CHOICES
    add_lunch_combo full-eng
    for f in `/bin/ls vendor/cm/vendorsetup.sh 2> /dev/null`
        do
            echo "including $f"
            . $f
        done
    unset f

    if [ $# -eq 0 ]; then
        # No arguments, so let's have the full menu
        lunch
    else
        echo "z$target" | grep -q "-"
        if [ $? -eq 0 ]; then
            # A buildtype was specified, assume a full device name
            lunch $target
        else
            # This is probably just the CM model name
            lunch cm_$target-userdebug
        fi
    fi
    return $?
}

alias bib=breakfast

function lunch()
{
    local answer

    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like? [aosp_arm-eng] "
        read answer
    fi

    local selection=

    if [ -z "$answer" ]
    then
        selection=aosp_arm-eng
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
    then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
        then
            selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
    then
        selection=$answer
    fi

    if [ -z "$selection" ]
    then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    export TARGET_BUILD_APPS=

    local product=$(echo -n $selection | sed -e "s/-.*$//")
    check_product $product
    if [ $? -ne 0 ]
    then
        # if we can't find a product, try to grab it off the CM github
        T=$(gettop)
        pushd $T > /dev/null
        build/tools/roomservice.py $product
        popd > /dev/null
        check_product $product
    else
        build/tools/roomservice.py $product true
    fi
    if [ $? -ne 0 ]
    then
        echo
        echo "** Don't have a product spec for: '$product'"
        echo "** Do you have the right repo manifest?"
        product=
    fi

    local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
    check_variant $variant
    if [ $? -ne 0 ]
    then
        echo
        echo "** Invalid variant: '$variant'"
        echo "** Must be one of ${VARIANT_CHOICES[@]}"
        variant=
    fi

    if [ -z "$product" -o -z "$variant" ]
    then
        echo
        return 1
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release

    echo

    fixup_common_out_dir

    set_stuff_for_environment
    printconfig
}

# Tab completion for lunch.
function _lunch()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=( $(compgen -W "${LUNCH_MENU_CHOICES[*]}" -- ${cur}) )
    return 0
}
complete -F _lunch lunch 2>/dev/null

# Configures the build to build unbundled apps.
# Run tapas with one ore more app names (from LOCAL_PACKAGE_NAME)
function tapas()
{
    local arch=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E '^(arm|x86|mips|armv5)$'))
    local variant=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E '^(user|userdebug|eng)$'))
    local apps=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E -v '^(user|userdebug|eng|arm|x86|mips|armv5)$'))

    if [ $(echo $arch | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build archs supplied: $arch"
        return
    fi
    if [ $(echo $variant | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build variants supplied: $variant"
        return
    fi

    local product=full
    case $arch in
      x86)   product=full_x86;;
      mips)  product=full_mips;;
      armv5) product=generic_armv5;;
    esac
    if [ -z "$variant" ]; then
        variant=eng
    fi
    if [ -z "$apps" ]; then
        apps=all
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release
    export TARGET_BUILD_APPS=$apps

    set_stuff_for_environment
    printconfig
}

function eat()
{
    if [ "$OUT" ] ; then
        MODVERSION=$(get_build_var CM_VERSION)
        ZIPFILE=rr-$MODVERSION.zip
        ZIPPATH=$OUT/$ZIPFILE
        if [ ! -f $ZIPPATH ] ; then
            echo "Nothing to eat"
            return 1
        fi
        adb start-server # Prevent unexpected starting server message from adb get-state in the next line
        if [ $(adb get-state) != device -a $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) != 0 ] ; then
            echo "No device is online. Waiting for one..."
            echo "Please connect USB and/or enable USB debugging"
            until [ $(adb get-state) = device -o $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) = 0 ];do
                sleep 1
            done
            echo "Device Found.."
        fi
    if (adb shell cat /system/build.prop | grep -q "ro.cm.device=$CM_BUILD");
    then
        # if adbd isn't root we can't write to /cache/recovery/
        adb root
        sleep 1
        adb wait-for-device
        # CWM command
        cat << EOF > /tmp/command
--sideload
EOF
        # TWRP command
        cat << EOF > /tmp/openrecoveryscript
sideload
EOF
        if adb push /tmp/command /cache/recovery/ && adb push /tmp/openrecoveryscript /cache/recovery/; then
            echo "Rebooting into recovery for sideload installation"
            adb reboot recovery
            adb kill-server
            adb wait-for-sideload
            echo "Device back online, trying to sideload"
            adb sideload $ZIPPATH
        fi
        rm /tmp/command
    else
        echo "Nothing to eat"
        return 1
    fi
    return $?
    else
        echo "The connected device does not appear to be $CM_BUILD, run away!"
    fi
}

function omnom
{
    brunch $*
    eat
}

function gettop
{
    local TOPFILE=build/core/envsetup.mk
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        echo $TOP
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                \cd ..
                T=`PWD= /bin/pwd -P`
            done
            \cd $HERE
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function m()
{
    T=$(gettop)
    if [ "$T" ]; then
        make -C $T -f build/core/main.mk $@
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function findmakefile()
{
    TOPFILE=build/core/envsetup.mk
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=`PWD= /bin/pwd`
        if [ -f "$T/Android.mk" ]; then
            echo $T/Android.mk
            \cd $HERE
            return
        fi
        \cd ..
    done
    \cd $HERE
}

function mm()
{
    local MM_MAKE=make
    local ARG=
    for ARG in $@ ; do
        if [ "$ARG" = mka ]; then
            MM_MAKE=mka
        fi
    done
    # If we're sitting in the root of the build tree, just do a
    # normal make.
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        $MM_MAKE $@
    else
        # Find the closest Android.mk file.
        T=$(gettop)
        local M=$(findmakefile)
        local MODULES=
        local GET_INSTALL_PATH=
        local ARGS=
        # Remove the path to top as the makefilepath needs to be relative
        local M=`echo $M|sed 's:'$T'/::'`
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        elif [ ! "$M" ]; then
            echo "Couldn't locate a makefile from the current directory."
        else
            for ARG in $@; do
                case $ARG in
                  GET-INSTALL-PATH) GET_INSTALL_PATH=$ARG;;
                esac
            done
            if [ -n "$GET_INSTALL_PATH" ]; then
              MODULES=
              ARGS=GET-INSTALL-PATH
            else
              MODULES=all_modules
              ARGS=$@
            fi
            ONE_SHOT_MAKEFILE=$M $MM_MAKE -C $T -f build/core/main.mk $MODULES $ARGS
        fi
    fi
}

function mmm()
{
    local MMM_MAKE=make
    T=$(gettop)
    if [ "$T" ]; then
        local MAKEFILE=
        local MODULES=
        local ARGS=
        local DIR TO_CHOP
        local GET_INSTALL_PATH=
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        for DIR in $DIRS ; do
            MODULES=`echo $DIR | sed -n -e 's/.*:\(.*$\)/\1/p' | sed 's/,/ /'`
            if [ "$MODULES" = "" ]; then
                MODULES=all_modules
            fi
            DIR=`echo $DIR | sed -e 's/:.*//' -e 's:/$::'`
            if [ -f $DIR/Android.mk ]; then
                local TO_CHOP=`(\cd -P -- $T && pwd -P) | wc -c | tr -d ' '`
                local TO_CHOP=`expr $TO_CHOP + 1`
                local START=`PWD= /bin/pwd`
                local MFILE=`echo $START | cut -c${TO_CHOP}-`
                if [ "$MFILE" = "" ] ; then
                    MFILE=$DIR/Android.mk
                else
                    MFILE=$MFILE/$DIR/Android.mk
                fi
                MAKEFILE="$MAKEFILE $MFILE"
            else
                case $DIR in
                  mka) MMM_MAKE=mka;;
                  showcommands | snod | dist | incrementaljavac) ARGS="$ARGS $DIR";;
                  GET-INSTALL-PATH) GET_INSTALL_PATH=$DIR;;
                  *) echo "No Android.mk in $DIR."; return 1;;
                esac
            fi
        done
        if [ -n "$GET_INSTALL_PATH" ]; then
          ARGS=$GET_INSTALL_PATH
          MODULES=
        fi
        ONE_SHOT_MAKEFILE="$MAKEFILE" $MMM_MAKE -C $T -f build/core/main.mk $DASH_ARGS $MODULES $ARGS
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function mma()
{
  if [ -f build/core/envsetup.mk -a -f Makefile ]; then
    make $@
  else
    T=$(gettop)
    if [ ! "$T" ]; then
      echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
    local MY_PWD=`PWD= /bin/pwd|sed 's:'$T'/::'`
    make -C $T -f build/core/main.mk $@ all_modules BUILD_MODULES_IN_PATHS="$MY_PWD"
  fi
}

function mmma()
{
  T=$(gettop)
  if [ "$T" ]; then
    local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
    local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
    local MY_PWD=`PWD= /bin/pwd`
    if [ "$MY_PWD" = "$T" ]; then
      MY_PWD=
    else
      MY_PWD=`echo $MY_PWD|sed 's:'$T'/::'`
    fi
    local DIR=
    local MODULE_PATHS=
    local ARGS=
    for DIR in $DIRS ; do
      if [ -d $DIR ]; then
        if [ "$MY_PWD" = "" ]; then
          MODULE_PATHS="$MODULE_PATHS $DIR"
        else
          MODULE_PATHS="$MODULE_PATHS $MY_PWD/$DIR"
        fi
      else
        case $DIR in
          showcommands | snod | dist | incrementaljavac) ARGS="$ARGS $DIR";;
          *) echo "Couldn't find directory $DIR"; return 1;;
        esac
      fi
    done
    make -C $T -f build/core/main.mk $DASH_ARGS $ARGS all_modules BUILD_MODULES_IN_PATHS="$MODULE_PATHS"
  else
    echo "Couldn't locate the top of the tree.  Try setting TOP."
  fi
}

function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        \cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cout()
{
    if [  "$OUT" ]; then
        cd $OUT
    else
        echo "Couldn't locate out directory.  Try setting OUT."
    fi
}

function cproj()
{
    TOPFILE=build/core/envsetup.mk
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            \cd $T
            return
        fi
        \cd ..
    done
    \cd $HERE
    echo "can't find Android.mk"
}

# simplified version of ps; output in the form
# <pid> <procname>
function qpid() {
    local prepend=''
    local append=''
    if [ "$1" = "--exact" ]; then
        prepend=' '
        append='$'
        shift
    elif [ "$1" = "--help" -o "$1" = "-h" ]; then
		echo "usage: qpid [[--exact] <process name|pid>"
		return 255
	fi

    local EXE="$1"
    if [ "$EXE" ] ; then
		qpid | \grep "$prepend$EXE$append"
	else
		adb shell ps \
			| tr -d '\r' \
			| sed -e 1d -e 's/^[^ ]* *\([0-9]*\).* \([^ ]*\)$/\1 \2/'
	fi
}

function pid()
{
    local prepend=''
    local append=''
    if [ "$1" = "--exact" ]; then
        prepend=' '
        append='$'
        shift
    fi
    local EXE="$1"
    if [ "$EXE" ] ; then
        local PID=`adb shell ps \
            | tr -d '\r' \
            | \grep "$prepend$EXE$append" \
            | sed -e 's/^[^ ]* *\([0-9]*\).*$/\1/'`
        echo "$PID"
    else
        echo "usage: pid [--exact] <process name>"
		return 255
    fi
}

# systemstack - dump the current stack trace of all threads in the system process
# to the usual ANR traces file
function systemstack()
{
    stacks system_server
}

function stacks()
{
    if [[ $1 =~ ^[0-9]+$ ]] ; then
        local PID="$1"
    elif [ "$1" ] ; then
        local PIDLIST="$(pid $1)"
        if [[ $PIDLIST =~ ^[0-9]+$ ]] ; then
            local PID="$PIDLIST"
        elif [ "$PIDLIST" ] ; then
            echo "more than one process: $1"
        else
            echo "no such process: $1"
        fi
    else
        echo "usage: stacks [pid|process name]"
    fi

    if [ "$PID" ] ; then
        # Determine whether the process is native
        if adb shell ls -l /proc/$PID/exe | grep -q /system/bin/app_process ; then
            # Dump stacks of Dalvik process
            local TRACES=/data/anr/traces.txt
            local ORIG=/data/anr/traces.orig
            local TMP=/data/anr/traces.tmp

            # Keep original traces to avoid clobbering
            adb shell mv $TRACES $ORIG

            # Make sure we have a usable file
            adb shell touch $TRACES
            adb shell chmod 666 $TRACES

            # Dump stacks and wait for dump to finish
            adb shell kill -3 $PID
            adb shell notify $TRACES >/dev/null

            # Restore original stacks, and show current output
            adb shell mv $TRACES $TMP
            adb shell mv $ORIG $TRACES
            adb shell cat $TMP
        else
            # Dump stacks of native process
            adb shell debuggerd -b $PID
        fi
    fi
}

function gdbwrapper()
{
    $ANDROID_TOOLCHAIN/$GDB -x "$@"
}

function gdbclient()
{
   local OUT_ROOT=$(get_abs_build_var PRODUCT_OUT)
   local OUT_SYMBOLS=$(get_abs_build_var TARGET_OUT_UNSTRIPPED)
   local OUT_SO_SYMBOLS=$(get_abs_build_var TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)
   local OUT_EXE_SYMBOLS=$(get_abs_build_var TARGET_OUT_EXECUTABLES_UNSTRIPPED)
   local PREBUILTS=$(get_abs_build_var ANDROID_PREBUILTS)
   local ARCH=$(get_build_var TARGET_ARCH)
   local GDB
   case "$ARCH" in
       x86) GDB=i686-linux-android-gdb;;
       arm) GDB=arm-linux-androideabi-gdb;;
       mips) GDB=mipsel-linux-android-gdb;;
       *) echo "Unknown arch $ARCH"; return 1;;
   esac

   if [ "$OUT_ROOT" -a "$PREBUILTS" ]; then
       local EXE="$1"
       if [ "$EXE" ] ; then
           EXE=$1
       else
           EXE="app_process"
       fi

       local PORT="$2"
       if [ "$PORT" ] ; then
           PORT=$2
       else
           PORT=":5039"
       fi

       local PID="$3"
       if [ "$PID" ] ; then
           if [[ ! "$PID" =~ ^[0-9]+$ ]] ; then
               PID=`pid $3`
               if [[ ! "$PID" =~ ^[0-9]+$ ]] ; then
                   # that likely didn't work because of returning multiple processes
                   # try again, filtering by root processes (don't contain colon)
                   PID=`adb shell ps | \grep $3 | \grep -v ":" | awk '{print $2}'`
                   if [[ ! "$PID" =~ ^[0-9]+$ ]]
                   then
                       echo "Couldn't resolve '$3' to single PID"
                       return 1
                   else
                       echo ""
                       echo "WARNING: multiple processes matching '$3' observed, using root process"
                       echo ""
                   fi
               fi
           fi
           adb forward "tcp$PORT" "tcp$PORT"
           adb shell gdbserver $PORT --attach $PID &
           sleep 2
       else
               echo ""
               echo "If you haven't done so already, do this first on the device:"
               echo "    gdbserver $PORT /system/bin/$EXE"
                   echo " or"
               echo "    gdbserver $PORT --attach <PID>"
               echo ""
       fi

       echo >|"$OUT_ROOT/gdbclient.cmds" "set solib-absolute-prefix $OUT_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "set solib-search-path $OUT_SO_SYMBOLS:$OUT_SO_SYMBOLS/hw:$OUT_SO_SYMBOLS/ssl/engines:$OUT_SO_SYMBOLS/drm:$OUT_SO_SYMBOLS/egl:$OUT_SO_SYMBOLS/soundfx"
       echo >>"$OUT_ROOT/gdbclient.cmds" "source $ANDROID_BUILD_TOP/development/scripts/gdb/dalvik.gdb"
       echo >>"$OUT_ROOT/gdbclient.cmds" "target remote $PORT"
       echo >>"$OUT_ROOT/gdbclient.cmds" ""

       gdbwrapper "$OUT_ROOT/gdbclient.cmds" "$OUT_EXE_SYMBOLS/$EXE"
  else
       echo "Unable to determine build system output dir."
   fi

}

case `uname -s` in
    Darwin)
        function sgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.(c|h|cpp|S|java|xml|sh|mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        ;;
    *)
        function sgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.\(c\|h\|cpp\|S\|java\|xml\|sh\|mk\)' -print0 | xargs -0 grep --color -n "$@"
        }
        ;;
esac

function gettargetarch
{
    get_build_var TARGET_ARCH
}

function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o  -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function resgrep()
{
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
}

function mangrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -name 'AndroidManifest.xml' -print0 | xargs -0 grep --color -n "$@"
}

function sepgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -name sepolicy -type d -print0 | xargs -0 grep --color -n -r --exclude-dir=\.git "$@"
}

case `uname -s` in
    Darwin)
        function mgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -iregex '.*/(Makefile|Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o -type f -iregex '.*\.(c|h|cpp|S|java|xml)' -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
    *)
        function mgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
esac

function getprebuilt
{
    get_abs_build_var ANDROID_PREBUILTS
}

function tracedmdump()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi
    local prebuiltdir=$(getprebuilt)
    local arch=$(gettargetarch)
    local KERNEL=$T/prebuilts/qemu-kernel/$arch/vmlinux-qemu

    local TRACE=$1
    if [ ! "$TRACE" ] ; then
        echo "usage:  tracedmdump  tracename"
        return
    fi

    if [ ! -r "$KERNEL" ] ; then
        echo "Error: cannot find kernel: '$KERNEL'"
        return
    fi

    local BASETRACE=$(basename $TRACE)
    if [ "$BASETRACE" = "$TRACE" ] ; then
        TRACE=$ANDROID_PRODUCT_OUT/traces/$TRACE
    fi

    echo "post-processing traces..."
    rm -f $TRACE/qtrace.dexlist
    post_trace $TRACE
    if [ $? -ne 0 ]; then
        echo "***"
        echo "*** Error: malformed trace.  Did you remember to exit the emulator?"
        echo "***"
        return
    fi
    echo "generating dexlist output..."
    /bin/ls $ANDROID_PRODUCT_OUT/system/framework/*.jar $ANDROID_PRODUCT_OUT/system/app/*.apk $ANDROID_PRODUCT_OUT/data/app/*.apk 2>/dev/null | xargs dexlist > $TRACE/qtrace.dexlist
    echo "generating dmtrace data..."
    q2dm -r $ANDROID_PRODUCT_OUT/symbols $TRACE $KERNEL $TRACE/dmtrace || return
    echo "generating html file..."
    dmtracedump -h $TRACE/dmtrace >| $TRACE/dmtrace.html || return
    echo "done, see $TRACE/dmtrace.html for details"
    echo "or run:"
    echo "    traceview $TRACE/dmtrace"
}

# communicate with a running device or emulator, set up necessary state,
# and run the hat command.
function runhat()
{
    # process standard adb options
    local adbTarget=""
    if [ "$1" = "-d" -o "$1" = "-e" ]; then
        adbTarget=$1
        shift 1
    elif [ "$1" = "-s" ]; then
        adbTarget="$1 $2"
        shift 2
    fi
    local adbOptions=${adbTarget}
    #echo adbOptions = ${adbOptions}

    # runhat options
    local targetPid=$1

    if [ "$targetPid" = "" ]; then
        echo "Usage: runhat [ -d | -e | -s serial ] target-pid"
        return
    fi

    # confirm hat is available
    if [ -z $(which hat) ]; then
        echo "hat is not available in this configuration."
        return
    fi

    # issue "am" command to cause the hprof dump
    local sdcard=$(adb ${adbOptions} shell echo -n '$EXTERNAL_STORAGE')
    local devFile=$sdcard/hprof-$targetPid
    #local devFile=/data/local/hprof-$targetPid
    echo "Poking $targetPid and waiting for data..."
    echo "Storing data at $devFile"
    adb ${adbOptions} shell am dumpheap $targetPid $devFile
    echo "Press enter when logcat shows \"hprof: heap dump completed\""
    echo -n "> "
    read

    local localFile=/tmp/$$-hprof

    echo "Retrieving file $devFile..."
    adb ${adbOptions} pull $devFile $localFile

    adb ${adbOptions} shell rm $devFile

    echo "Running hat on $localFile"
    echo "View the output by pointing your browser at http://localhost:7000/"
    echo ""
    hat -JXmx512m $localFile
}

function getbugreports()
{
    local reports=(`adb shell ls /sdcard/bugreports | tr -d '\r'`)

    if [ ! "$reports" ]; then
        echo "Could not locate any bugreports."
        return
    fi

    local report
    for report in ${reports[@]}
    do
        echo "/sdcard/bugreports/${report}"
        adb pull /sdcard/bugreports/${report} ${report}
        gunzip ${report}
    done
}

function getsdcardpath()
{
    adb ${adbOptions} shell echo -n \$\{EXTERNAL_STORAGE\}
}

function getscreenshotpath()
{
    echo "$(getsdcardpath)/Pictures/Screenshots"
}

function getlastscreenshot()
{
    local screenshot_path=$(getscreenshotpath)
    local screenshot=`adb ${adbOptions} ls ${screenshot_path} | grep Screenshot_[0-9-]*.*\.png | sort -rk 3 | cut -d " " -f 4 | head -n 1`
    if [ "$screenshot" = "" ]; then
        echo "No screenshots found."
        return
    fi
    echo "${screenshot}"
    adb ${adbOptions} pull ${screenshot_path}/${screenshot}
}

function startviewserver()
{
    local port=4939
    if [ $# -gt 0 ]; then
            port=$1
    fi
    adb shell service call window 1 i32 $port
}

function stopviewserver()
{
    adb shell service call window 2
}

function isviewserverstarted()
{
    adb shell service call window 3
}

function key_home()
{
    adb shell input keyevent 3
}

function key_back()
{
    adb shell input keyevent 4
}

function key_menu()
{
    adb shell input keyevent 82
}

function smoketest()
{
    if [ ! "$ANDROID_PRODUCT_OUT" ]; then
        echo "Couldn't locate output files.  Try running 'lunch' first." >&2
        return
    fi
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    (\cd "$T" && mmm tests/SmokeTest) &&
      adb uninstall com.android.smoketest > /dev/null &&
      adb uninstall com.android.smoketest.tests > /dev/null &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTestApp.apk &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTest.apk &&
      adb shell am instrument -w com.android.smoketest.tests/android.test.InstrumentationTestRunner
}

# simple shortcut to the runtest command
function runtest()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    ("$T"/development/testrunner/runtest.py $@)
}

function godir () {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (\cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(\grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    \cd $T/$pathname
}

function cmremote()
{
    git remote rm cmremote 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    GERRIT_REMOTE=$(cat .git/config  | grep git://github.com | awk '{ print $NF }' | sed s#git://github.com/##g)
    if [ -z "$GERRIT_REMOTE" ]
    then
        GERRIT_REMOTE=$(cat .git/config  | grep http://github.com | awk '{ print $NF }' | sed s#http://github.com/##g)
        if [ -z "$GERRIT_REMOTE" ]
        then
          echo Unable to set up the git remote, are you in the root of the repo?
          return 0
        fi
    fi
    CMUSER=`git config --get review.review.cyanogenmod.org.username`
    if [ -z "$CMUSER" ]
    then
        git remote add cmremote ssh://review.cyanogenmod.org:29418/$GERRIT_REMOTE
    else
        git remote add cmremote ssh://$CMUSER@review.cyanogenmod.org:29418/$GERRIT_REMOTE
    fi
    echo You can now push to "cmremote".
}

function aospremote()
{
    git remote rm aosp 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    PROJECT=`pwd -P | sed s#$ANDROID_BUILD_TOP/##g`
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add aosp https://android.googlesource.com/$PFX$PROJECT
    echo "Remote 'aosp' created"
}

function cafremote()
{
    git remote rm caf 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    PROJECT=`pwd -P | sed s#$ANDROID_BUILD_TOP/##g`
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add caf git://codeaurora.org/$PFX$PROJECT
    echo "Remote 'caf' created"
}

function installboot()
{
    if [ ! -e "$OUT/recovery/root/etc/recovery.fstab" ];
    then
        echo "No recovery.fstab found. Build recovery first."
        return 1
    fi
    if [ ! -e "$OUT/boot.img" ];
    then
        echo "No boot.img found. Run make bootimage first."
        return 1
    fi
    PARTITION=`grep "^\/boot" $OUT/recovery/root/etc/recovery.fstab | awk {'print $3'}`
    PARTITION_TYPE=`grep "^\/boot" $OUT/recovery/root/etc/recovery.fstab | awk {'print $2'}`
    if [ -z "$PARTITION" ];
    then
        # Try for RECOVERY_FSTAB_VERSION = 2
        PARTITION=`grep "[[:space:]]\/boot[[:space:]]" $OUT/recovery/root/etc/recovery.fstab | awk {'print $1'}`
        PARTITION_TYPE=`grep "[[:space:]]\/boot[[:space:]]" $OUT/recovery/root/etc/recovery.fstab | awk {'print $3'}`
        if [ -z "$PARTITION" ];
        then
            echo "Unable to determine boot partition."
            return 1
        fi
    fi
    adb start-server
    adb wait-for-online
    adb root
    sleep 1
    adb wait-for-online shell mount /system 2>&1 > /dev/null
    adb wait-for-online remount
    if (adb shell cat /system/build.prop | grep -q "ro.cm.device=$CM_BUILD");
    then
        adb push $OUT/boot.img /cache/
        for i in $OUT/system/lib/modules/*;
        do
            adb push $i /system/lib/modules/
        done
        if [ "$PARTITION_TYPE" == "mtd" ];
        then
            adb shell flash_image $PARTITION /cache/boot.img
        else
            adb shell dd if=/cache/boot.img of=$PARTITION
        fi
        adb shell chmod 644 /system/lib/modules/*
        echo "Installation complete."
    else
        echo "The connected device does not appear to be $CM_BUILD, run away!"
    fi
}

function installrecovery()
{
    if [ ! -e "$OUT/recovery/root/etc/recovery.fstab" ];
    then
        echo "No recovery.fstab found. Build recovery first."
        return 1
    fi
    if [ ! -e "$OUT/recovery.img" ];
    then
        echo "No recovery.img found. Run make recoveryimage first."
        return 1
    fi
    PARTITION=`grep "^\/recovery" $OUT/recovery/root/etc/recovery.fstab | awk {'print $3'}`
    if [ -z "$PARTITION" ];
    then
        # Try for RECOVERY_FSTAB_VERSION = 2
        PARTITION=`grep "[[:space:]]\/recovery[[:space:]]" $OUT/recovery/root/etc/recovery.fstab | awk {'print $1'}`
        PARTITION_TYPE=`grep "[[:space:]]\/recovery[[:space:]]" $OUT/recovery/root/etc/recovery.fstab | awk {'print $3'}`
        if [ -z "$PARTITION" ];
        then
            echo "Unable to determine recovery partition."
            return 1
        fi
    fi
    adb start-server
    adb wait-for-online
    adb root
    sleep 1
    adb wait-for-online shell mount /system 2>&1 >> /dev/null
    adb wait-for-online remount
    if (adb shell cat /system/build.prop | grep -q "ro.cm.device=$CM_BUILD");
    then
        adb push $OUT/recovery.img /cache/
        adb shell dd if=/cache/recovery.img of=$PARTITION
        echo "Installation complete."
    else
        echo "The connected device does not appear to be $CM_BUILD, run away!"
    fi
}

function makerecipe() {
  if [ -z "$1" ]
  then
    echo "No branch name provided."
    return 1
  fi
  cd .repo
  mv local_manifest.xml local_manifest.xml.bak
  cd ..
  cd android
  sed -i s/'default revision=.*'/'default revision="refs\/heads\/'$1'"'/ default.xml
  git commit -a -m "$1"
  cd ..

  repo forall -c '

  if [ "$REPO_REMOTE" == "github" ]
  then
    pwd
    cmremote
    git push cmremote HEAD:refs/heads/'$1'
  fi
  '

  cd .repo
  mv local_manifest.xml.bak local_manifest.xml
  cd ..
}

function cmgerrit() {
    if [ $# -eq 0 ]; then
        $FUNCNAME help
        return 1
    fi
    local user=`git config --get review.review.cyanogenmod.org.username`
    local review=`git config --get remote.github.review`
    local project=`git config --get remote.github.projectname`
    local command=$1
    shift
    case $command in
        help)
            if [ $# -eq 0 ]; then
                cat <<EOF
Usage:
    $FUNCNAME COMMAND [OPTIONS] [CHANGE-ID[/PATCH-SET]][{@|^|~|:}ARG] [-- ARGS]

Commands:
    fetch   Just fetch the change as FETCH_HEAD
    help    Show this help, or for a specific command
    pull    Pull a change into current branch
    push    Push HEAD or a local branch to Gerrit for a specific branch

Any other Git commands that support refname would work as:
    git fetch URL CHANGE && git COMMAND OPTIONS FETCH_HEAD{@|^|~|:}ARG -- ARGS

See '$FUNCNAME help COMMAND' for more information on a specific command.

Example:
    $FUNCNAME checkout -b topic 1234/5
works as:
    git fetch http://DOMAIN/p/PROJECT refs/changes/34/1234/5 \\
      && git checkout -b topic FETCH_HEAD
will checkout a new branch 'topic' base on patch-set 5 of change 1234.
Patch-set 1 will be fetched if omitted.
EOF
                return
            fi
            case $1 in
                __cmg_*) echo "For internal use only." ;;
                changes|for)
                    if [ "$FUNCNAME" = "cmgerrit" ]; then
                        echo "'$FUNCNAME $1' is deprecated."
                    fi
                    ;;
                help) $FUNCNAME help ;;
                fetch|pull) cat <<EOF
usage: $FUNCNAME $1 [OPTIONS] CHANGE-ID[/PATCH-SET]

works as:
    git $1 OPTIONS http://DOMAIN/p/PROJECT \\
      refs/changes/HASH/CHANGE-ID/{PATCH-SET|1}

Example:
    $FUNCNAME $1 1234
will $1 patch-set 1 of change 1234
EOF
                    ;;
                push) cat <<EOF
usage: $FUNCNAME push [OPTIONS] [LOCAL_BRANCH:]REMOTE_BRANCH

works as:
    git push OPTIONS ssh://USER@DOMAIN:29418/PROJECT \\
      {LOCAL_BRANCH|HEAD}:refs/for/REMOTE_BRANCH

Example:
    $FUNCNAME push fix6789:gingerbread
will push local branch 'fix6789' to Gerrit for branch 'gingerbread'.
HEAD will be pushed from local if omitted.
EOF
                    ;;
                *)
                    $FUNCNAME __cmg_err_not_supported $1 && return
                    cat <<EOF
usage: $FUNCNAME $1 [OPTIONS] CHANGE-ID[/PATCH-SET][{@|^|~|:}ARG] [-- ARGS]

works as:
    git fetch http://DOMAIN/p/PROJECT \\
      refs/changes/HASH/CHANGE-ID/{PATCH-SET|1} \\
      && git $1 OPTIONS FETCH_HEAD{@|^|~|:}ARG -- ARGS
EOF
                    ;;
            esac
            ;;
        __cmg_get_ref)
            $FUNCNAME __cmg_err_no_arg $command $# && return 1
            local change_id patchset_id hash
            case $1 in
                */*)
                    change_id=${1%%/*}
                    patchset_id=${1#*/}
                    ;;
                *)
                    change_id=$1
                    patchset_id=1
                    ;;
            esac
            hash=$(($change_id % 100))
            case $hash in
                [0-9]) hash="0$hash" ;;
            esac
            echo "refs/changes/$hash/$change_id/$patchset_id"
            ;;
        fetch|pull)
            $FUNCNAME __cmg_err_no_arg $command $# help && return 1
            $FUNCNAME __cmg_err_not_repo && return 1
            local change=$1
            shift
            git $command $@ http://$review/p/$project \
                $($FUNCNAME __cmg_get_ref $change) || return 1
            ;;
        push)
            $FUNCNAME __cmg_err_no_arg $command $# help && return 1
            $FUNCNAME __cmg_err_not_repo && return 1
            if [ -z "$user" ]; then
                echo >&2 "Gerrit username not found."
                return 1
            fi
            local local_branch remote_branch
            case $1 in
                *:*)
                    local_branch=${1%:*}
                    remote_branch=${1##*:}
                    ;;
                *)
                    local_branch=HEAD
                    remote_branch=$1
                    ;;
            esac
            shift
            git push $@ ssh://$user@$review:29418/$project \
                $local_branch:refs/for/$remote_branch || return 1
            ;;
        changes|for)
            if [ "$FUNCNAME" = "cmgerrit" ]; then
                echo >&2 "'$FUNCNAME $command' is deprecated."
            fi
            ;;
        __cmg_err_no_arg)
            if [ $# -lt 2 ]; then
                echo >&2 "'$FUNCNAME $command' missing argument."
            elif [ $2 -eq 0 ]; then
                if [ -n "$3" ]; then
                    $FUNCNAME help $1
                else
                    echo >&2 "'$FUNCNAME $1' missing argument."
                fi
            else
                return 1
            fi
            ;;
        __cmg_err_not_repo)
            if [ -z "$review" -o -z "$project" ]; then
                echo >&2 "Not currently in any reviewable repository."
            else
                return 1
            fi
            ;;
        __cmg_err_not_supported)
            $FUNCNAME __cmg_err_no_arg $command $# && return
            case $1 in
                #TODO: filter more git commands that don't use refname
                init|add|rm|mv|status|clone|remote|bisect|config|stash)
                    echo >&2 "'$FUNCNAME $1' is not supported."
                    ;;
                *) return 1 ;;
            esac
            ;;
    #TODO: other special cases?
        *)
            $FUNCNAME __cmg_err_not_supported $command && return 1
            $FUNCNAME __cmg_err_no_arg $command $# help && return 1
            $FUNCNAME __cmg_err_not_repo && return 1
            local args="$@"
            local change pre_args refs_arg post_args
            case "$args" in
                *--\ *)
                    pre_args=${args%%-- *}
                    post_args="-- ${args#*-- }"
                    ;;
                *) pre_args="$args" ;;
            esac
            args=($pre_args)
            pre_args=
            if [ ${#args[@]} -gt 0 ]; then
                change=${args[${#args[@]}-1]}
            fi
            if [ ${#args[@]} -gt 1 ]; then
                pre_args=${args[0]}
                for ((i=1; i<${#args[@]}-1; i++)); do
                    pre_args="$pre_args ${args[$i]}"
                done
            fi
            while ((1)); do
                case $change in
                    ""|--)
                        $FUNCNAME help $command
                        return 1
                        ;;
                    *@*)
                        if [ -z "$refs_arg" ]; then
                            refs_arg="@${change#*@}"
                            change=${change%%@*}
                        fi
                        ;;
                    *~*)
                        if [ -z "$refs_arg" ]; then
                            refs_arg="~${change#*~}"
                            change=${change%%~*}
                        fi
                        ;;
                    *^*)
                        if [ -z "$refs_arg" ]; then
                            refs_arg="^${change#*^}"
                            change=${change%%^*}
                        fi
                        ;;
                    *:*)
                        if [ -z "$refs_arg" ]; then
                            refs_arg=":${change#*:}"
                            change=${change%%:*}
                        fi
                        ;;
                    *) break ;;
                esac
            done
            $FUNCNAME fetch $change \
                && git $command $pre_args FETCH_HEAD$refs_arg $post_args \
                || return 1
            ;;
    esac
}

function cmrebase() {
    local repo=$1
    local refs=$2
    local pwd="$(pwd)"
    local dir="$(gettop)/$repo"

    if [ -z $repo ] || [ -z $refs ]; then
        echo "CyanogenMod Gerrit Rebase Usage: "
        echo "      cmrebase <path to project> <patch IDs on Gerrit>"
        echo "      The patch IDs appear on the Gerrit commands that are offered."
        echo "      They consist on a series of numbers and slashes, after the text"
        echo "      refs/changes. For example, the ID in the following command is 26/8126/2"
        echo ""
        echo "      git[...]ges_apps_Camera refs/changes/26/8126/2 && git cherry-pick FETCH_HEAD"
        echo ""
        return
    fi

    if [ ! -d $dir ]; then
        echo "Directory $dir doesn't exist in tree."
        return
    fi
    cd $dir
    repo=$(cat .git/config  | grep git://github.com | awk '{ print $NF }' | sed s#git://github.com/##g)
    echo "Starting branch..."
    repo start tmprebase .
    echo "Bringing it up to date..."
    repo sync .
    echo "Fetching change..."
    git fetch "http://review.cyanogenmod.org/p/$repo" "refs/changes/$refs" && git cherry-pick FETCH_HEAD
    if [ "$?" != "0" ]; then
        echo "Error cherry-picking. Not uploading!"
        return
    fi
    echo "Uploading..."
    repo upload .
    echo "Cleaning up..."
    repo abandon tmprebase .
    cd $pwd
}

function mka() {
    case `uname -s` in
        Darwin)
            make -j `sysctl hw.ncpu|cut -d" " -f2` "$@"
            ;;
        *)
            schedtool -B -n 1 -e ionice -n 1 make -j$(cat /proc/cpuinfo | grep "^processor" | wc -l) "$@"
            ;;
    esac
}

function cmka() {
    if [ ! -z "$1" ]; then
        for i in "$@"; do
            case $i in
                bacon|otapackage|systemimage)
                    mka installclean
                    mka $i
                    ;;
                *)
                    mka clean-$i
                    mka $i
                    ;;
            esac
        done
    else
        mka clean
        mka
    fi
}

function repolastsync() {
    RLSPATH="$ANDROID_BUILD_TOP/.repo/.repopickle_fetchtimes"
    RLSLOCAL=$(date -d "$(stat -c %z $RLSPATH)" +"%e %b %Y, %T %Z")
    RLSUTC=$(date -d "$(stat -c %z $RLSPATH)" -u +"%e %b %Y, %T %Z")
    echo "Last repo sync: $RLSLOCAL / $RLSUTC"
}

function reposync() {
    case `uname -s` in
        Darwin)
            repo sync -j 4 "$@"
            ;;
        *)
            schedtool -B -n 1 -e ionice -n 1 `which repo` sync -j 4 "$@"
            ;;
    esac
}

function repodiff() {
    if [ -z "$*" ]; then
        echo "Usage: repodiff <ref-from> [[ref-to] [--numstat]]"
        return
    fi
    diffopts=$* repo forall -c \
      'echo "$REPO_PATH ($REPO_REMOTE)"; git diff ${diffopts} 2>/dev/null ;'
}

# Credit for color strip sed: http://goo.gl/BoIcm
function dopush()
{
    local func=$1
    shift

    adb start-server # Prevent unexpected starting server message from adb get-state in the next line
    if [ $(adb get-state) != device -a $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) != 0 ] ; then
        echo "No device is online. Waiting for one..."
        echo "Please connect USB and/or enable USB debugging"
        until [ $(adb get-state) = device -o $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) = 0 ];do
            sleep 1
        done
        echo "Device Found."
    fi

    if (adb shell cat /system/build.prop | grep -q "ro.cm.device=$CM_BUILD");
    then
    # retrieve IP and PORT info if we're using a TCP connection
    TCPIPPORT=$(adb devices | egrep '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[^0-9]+' \
        | head -1 | awk '{print $1}')
    adb root &> /dev/null
    sleep 0.3
    if [ -n "$TCPIPPORT" ]
    then
        # adb root just killed our connection
        # so reconnect...
        adb connect "$TCPIPPORT"
    fi
    adb wait-for-device &> /dev/null
    sleep 0.3
    adb remount &> /dev/null

    $func $* | tee $OUT/.log

    # Install: <file>
    LOC=$(cat $OUT/.log | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep 'Install' | cut -d ':' -f 2)

    # Copy: <file>
    LOC=$LOC $(cat $OUT/.log | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep 'Copy' | cut -d ':' -f 2)

    for FILE in $LOC; do
        # Get target file name (i.e. system/bin/adb)
        TARGET=$(echo $FILE | sed "s#$OUT/##")

        # Don't send files that are not under /system or /data
        if [ ! "echo $TARGET | egrep '^system\/' > /dev/null" -o \
               "echo $TARGET | egrep '^data\/' > /dev/null" ] ; then
            continue
        else
            case $TARGET in
            system/app/SystemUI.apk|system/framework/*)
                stop_n_start=true
            ;;
            *)
                stop_n_start=false
            ;;
            esac
            if $stop_n_start ; then adb shell stop ; fi
            echo "Pushing: $TARGET"
            adb push $FILE $TARGET
            if $stop_n_start ; then adb shell start ; fi
        fi
    done
    rm -f $OUT/.log
    return 0
    else
        echo "The connected device does not appear to be $CM_BUILD, run away!"
    fi
}

alias mmp='dopush mm'
alias mmmp='dopush mmm'
alias mkap='dopush mka'
alias cmkap='dopush cmka'

function repopick() {
    T=$(gettop)
    $T/build/tools/repopick.py $@
}

function fixup_common_out_dir() {
    common_out_dir=$(get_build_var OUT_DIR)/target/common
    target_device=$(get_build_var TARGET_DEVICE)
    if [ ! -z $CM_FIXUP_COMMON_OUT ]; then
        if [ -d ${common_out_dir} ] && [ ! -L ${common_out_dir} ]; then
            mv ${common_out_dir} ${common_out_dir}-${target_device}
            ln -s ${common_out_dir}-${target_device} ${common_out_dir}
        else
            [ -L ${common_out_dir} ] && rm ${common_out_dir}
            mkdir -p ${common_out_dir}-${target_device}
            ln -s ${common_out_dir}-${target_device} ${common_out_dir}
        fi
    else
        [ -L ${common_out_dir} ] && rm ${common_out_dir}
        mkdir -p ${common_out_dir}
    fi
}


# Force JAVA_HOME to point to java 1.6 if it isn't already set
function set_java_home() {
    if [ ! "$JAVA_HOME" ]; then
        case `uname -s` in
            Darwin)
                export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
                ;;
            *)
                export JAVA_HOME=/usr/lib/jvm/java-6-sun
                ;;
        esac
    fi
}

# Print colored exit condition
function pez {
    "$@"
    local retval=$?
    if [ $retval -ne 0 ]
    then
        echo -e "\e[0;31mFAILURE\e[00m"
    else
        echo -e "\e[0;32mSUCCESS\e[00m"
    fi
    return $retval
}

if [ "x$SHELL" != "x/bin/bash" ]; then
    case `ps -o command -p $$` in
        *bash*)
            ;;
        *zsh*)
            ;;
        *)
            echo "WARNING: Only bash and zsh are supported, use of other shell may lead to erroneous results"
            ;;
    esac
fi

# Execute the contents of any vendorsetup.sh files we can find.
for f in `/bin/ls vendor/*/vendorsetup.sh vendor/*/*/vendorsetup.sh device/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f

# Add completions
check_bash_version && {
    dirs="sdk/bash_completion vendor/cm/bash_completion"
    for dir in $dirs; do
    if [ -d ${dir} ]; then
        for f in `/bin/ls ${dir}/[a-z]*.bash 2> /dev/null`; do
            echo "including $f"
            . $f
        done
    fi
    done
}

export ANDROID_BUILD_TOP=$(gettop)
