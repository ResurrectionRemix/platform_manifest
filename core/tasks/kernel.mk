#Android makefile to build kernel as a part of Android Build

TARGET_AUTO_KDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/kernel/g')

## Externally influenced variables
# kernel location - optional, defaults to kernel/<vendor>/<device>
TARGET_KERNEL_SOURCE ?= $(TARGET_AUTO_KDIR)
KERNEL_SRC := $(TARGET_KERNEL_SOURCE)
# kernel configuration - mandatory
KERNEL_DEFCONFIG := $(TARGET_KERNEL_CONFIG)

## Internal variables
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config

ifeq ($(BOARD_USES_UBOOT),true)
	TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/uImage
	TARGET_PREBUILT_INT_KERNEL_TYPE := uImage
else ifeq ($(BOARD_USES_UNCOMPRESSED_BOOT),true)
	TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/Image
	TARGET_PREBUILT_INT_KERNEL_TYPE := Image
else
	TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/zImage
	TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
endif

ifeq "$(wildcard $(KERNEL_SRC) )" ""
    ifneq ($(TARGET_PREBUILT_KERNEL),)
        HAS_PREBUILT_KERNEL := true
        NEEDS_KERNEL_COPY := true
    else
        $(foreach cf,$(PRODUCT_COPY_FILES), \
            $(eval _src := $(call word-colon,1,$(cf))) \
            $(eval _dest := $(call word-colon,2,$(cf))) \
            $(ifeq kernel,$(_dest), \
                $(eval HAS_PREBUILT_KERNEL := true)))
    endif

    ifneq ($(HAS_PREBUILT_KERNEL),)
        $(warning ***************************************************************)
        $(warning * Using prebuilt kernel binary instead of source              *)
        $(warning * THIS IS DEPRECATED, AND WILL BE DISCONTINUED                *)
        $(warning * Please configure your device to download the kernel         *)
        $(warning * source repository to $(KERNEL_SRC))
        $(warning * See http://wiki.cyanogenmod.com/wiki/Integrated_kernel_building)
        $(warning * for more information                                        *)
        $(warning ***************************************************************)
        FULL_KERNEL_BUILD := false
        KERNEL_BIN := $(TARGET_PREBUILT_KERNEL)
    else
        $(warning ***************************************************************)
        $(warning *                                                             *)
        $(warning * No kernel source found, and no fallback prebuilt defined.   *)
        $(warning * Please make sure your device is properly configured to      *)
        $(warning * download the kernel repository to $(KERNEL_SRC))
        $(warning * and add the TARGET_KERNEL_CONFIG variable to BoardConfig.mk *)
        $(warning *                                                             *)
        $(warning * As an alternative, define the TARGET_PREBUILT_KERNEL        *)
        $(warning * variable with the path to the prebuilt binary kernel image  *)
        $(warning * in your BoardConfig.mk file                                 *)
        $(warning *                                                             *)
        $(warning ***************************************************************)
        $(error "NO KERNEL")
    endif
else
    NEEDS_KERNEL_COPY := true
    ifeq ($(TARGET_KERNEL_CONFIG),)
        $(warning **********************************************************)
        $(warning * Kernel source found, but no configuration was defined  *)
        $(warning * Please add the TARGET_KERNEL_CONFIG variable to your   *)
        $(warning * BoardConfig.mk file                                    *)
        $(warning **********************************************************)
        $(error "NO KERNEL CONFIG")
    else
        #$(info Kernel source found, building it)
        FULL_KERNEL_BUILD := true
        ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
        $(info Using uncompressed kernel)
            KERNEL_BIN := $(KERNEL_OUT)/piggy
        else
            KERNEL_BIN := $(TARGET_PREBUILT_INT_KERNEL)
        endif
    endif
endif

ifeq ($(FULL_KERNEL_BUILD),true)

KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules

define mv-modules
    mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
    if [ "$$mdpath" != "" ];then\
        mpath=`dirname $$mdpath`;\
        ko=`find $$mpath/kernel -type f -name *.ko`;\
        for i in $$ko; do $(ARM_EABI_TOOLCHAIN)/arm-eabi-strip --strip-unneeded $$i;\
        mv $$i $(KERNEL_MODULES_OUT)/; done;\
    fi
endef

define clean-module-folder
    mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
    if [ "$$mdpath" != "" ];then\
        mpath=`dirname $$mdpath`; rm -rf $$mpath;\
    fi
endef

ifeq ($(TARGET_ARCH),arm)
    ifneq ($(USE_CCACHE),)
     # search executable
      ccache =
      ifneq ($(strip $(wildcard $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_EXTRA_TAG)/ccache/ccache)),)
        ccache := $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_EXTRA_TAG)/ccache/ccache
      else
        ifneq ($(strip $(wildcard $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache)),)
          ccache := $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
        endif
      endif
    endif
    ifneq ($(TARGET_KERNEL_CUSTOM_TOOLCHAIN),)
      ifeq ($(HOST_OS),darwin)
        ARM_CROSS_COMPILE:=CROSS_COMPILE="$(ccache) $(ANDROID_BUILD_TOP)/prebuilt/darwin-x86/toolchain/$(TARGET_KERNEL_CUSTOM_TOOLCHAIN)/bin/arm-eabi-"
      else
        ARM_CROSS_COMPILE:=CROSS_COMPILE="$(ccache) $(ANDROID_BUILD_TOP)/prebuilt/linux-x86/toolchain/$(TARGET_KERNEL_CUSTOM_TOOLCHAIN)/bin/arm-eabi-"
      endif
    else
      ARM_CROSS_COMPILE:=CROSS_COMPILE="$(ccache) $(ARM_EABI_TOOLCHAIN)/arm-eabi-"
    endif
    ccache = 
endif

ifeq ($(TARGET_KERNEL_MODULES),)
    TARGET_KERNEL_MODULES := no-external-modules
endif

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)
	mkdir -p $(KERNEL_MODULES_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) $(KERNEL_DEFCONFIG)

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

TARGET_KERNEL_BINARIES: $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)
	-$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules
	-$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules_install
	$(mv-modules)
	$(clean-module-folder)

$(TARGET_KERNEL_MODULES): TARGET_KERNEL_BINARIES

$(TARGET_PREBUILT_INT_KERNEL): $(TARGET_KERNEL_MODULES)
	$(mv-modules)
	$(clean-module-folder)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) headers_install

endif # FULL_KERNEL_BUILD

## Install it

ifeq ($(NEEDS_KERNEL_COPY),true)
file := $(INSTALLED_KERNEL_TARGET)
ALL_PREBUILT += $(file)
$(file) : $(KERNEL_BIN) | $(ACP)
	$(transform-prebuilt-to-target)

ALL_PREBUILT += $(INSTALLED_KERNEL_TARGET)
endif
