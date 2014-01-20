# This makefile is used to generate extra images for QCOM targets
# persist, device tree & NAND images required for different QCOM targets.

# These variables are required to make sure that the required
# files/targets are available before generating NAND images.
# This file is included from device/qcom/<TARGET>/AndroidBoard.mk
# and gets parsed before build/core/Makefile, which has these
# variables defined. build/core/Makefile will overwrite these
# variables again.
INSTALLED_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/boot.img
INSTALLED_RAMDISK_TARGET := $(PRODUCT_OUT)/ramdisk.img
INSTALLED_SYSTEMIMAGE := $(PRODUCT_OUT)/system.img
INSTALLED_USERDATAIMAGE_TARGET := $(PRODUCT_OUT)/userdata.img
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
recovery_ramdisk := $(PRODUCT_OUT)/ramdisk-recovery.img

#----------------------------------------------------------------------
# Generate secure boot & recovery image
#----------------------------------------------------------------------
ifeq ($(TARGET_BOOTIMG_SIGNED),true)
INSTALLED_SEC_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/boot.img.secure
INSTALLED_SEC_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img.secure

ifneq ($(BUILD_TINY_ANDROID),true)
intermediates := $(call intermediates-dir-for,PACKAGING,recovery_patch)
RECOVERY_FROM_BOOT_PATCH := $(intermediates)/recovery_from_boot.p
endif

ifndef TARGET_SHA_TYPE
  TARGET_SHA_TYPE := sha256
endif

define build-sec-image
	$(hide) mv -f $(1) $(1).nonsecure
	$(hide) openssl dgst -$(TARGET_SHA_TYPE) -binary $(1).nonsecure > $(1).$(TARGET_SHA_TYPE)
	$(hide) openssl rsautl -sign -in $(1).$(TARGET_SHA_TYPE) -inkey $(PRODUCT_PRIVATE_KEY) -out $(1).sig
	$(hide) dd if=/dev/zero of=$(1).sig.padded bs=$(BOARD_KERNEL_PAGESIZE) count=1
	$(hide) dd if=$(1).sig of=$(1).sig.padded conv=notrunc
	$(hide) cat $(1).nonsecure $(1).sig.padded > $(1).secure
	$(hide) rm -rf $(1).$(TARGET_SHA_TYPE) $(1).sig $(1).sig.padded
	$(hide) mv -f $(1).secure $(1)
endef

$(INSTALLED_SEC_BOOTIMAGE_TARGET): $(INSTALLED_BOOTIMAGE_TARGET) $(RECOVERY_FROM_BOOT_PATCH)
	$(hide) $(call build-sec-image,$(INSTALLED_BOOTIMAGE_TARGET))

ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_SEC_BOOTIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_SEC_BOOTIMAGE_TARGET)

$(INSTALLED_SEC_RECOVERYIMAGE_TARGET): $(INSTALLED_RECOVERYIMAGE_TARGET) $(RECOVERY_FROM_BOOT_PATCH)
	$(hide) $(call build-sec-image,$(INSTALLED_RECOVERYIMAGE_TARGET))

ifneq ($(BUILD_TINY_ANDROID),true)
ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_SEC_RECOVERYIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_SEC_RECOVERYIMAGE_TARGET)
endif # !BUILD_TINY_ANDROID
endif # TARGET_BOOTIMG_SIGNED

#----------------------------------------------------------------------
# Generate persist image (persist.img)
#----------------------------------------------------------------------
TARGET_OUT_PERSIST := $(PRODUCT_OUT)/persist

INTERNAL_PERSISTIMAGE_FILES := \
	$(filter $(TARGET_OUT_PERSIST)/%,$(ALL_DEFAULT_INSTALLED_MODULES))

INSTALLED_PERSISTIMAGE_TARGET := $(PRODUCT_OUT)/persist.img

define build-persistimage-target
    $(call pretty,"Target persist fs image: $(INSTALLED_PERSISTIMAGE_TARGET)")
    @mkdir -p $(TARGET_OUT_PERSIST)
    $(hide) $(MKEXTUSERIMG) -s $(TARGET_OUT_PERSIST) $@ ext4 persist $(BOARD_PERSISTIMAGE_PARTITION_SIZE)
    $(hide) chmod a+r $@
    $(hide) $(call assert-max-image-size,$@,$(BOARD_PERSISTIMAGE_PARTITION_SIZE),yaffs)
endef

$(INSTALLED_PERSISTIMAGE_TARGET): $(MKEXTUSERIMG) $(MAKE_EXT4FS) $(INTERNAL_PERSISTIMAGE_FILES)
	$(build-persistimage-target)

ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_PERSISTIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_PERSISTIMAGE_TARGET)


#----------------------------------------------------------------------
# Generate device tree image (dt.img)
#----------------------------------------------------------------------
ifeq ($(strip $(BOARD_KERNEL_SEPARATED_DT)),true)
ifeq ($(strip $(BUILD_TINY_ANDROID)),true)
include device/qcom/common/dtbtool/Android.mk
endif

DTBTOOL := $(HOST_OUT_EXECUTABLES)/dtbTool$(HOST_EXECUTABLE_SUFFIX)

INSTALLED_DTIMAGE_TARGET := $(PRODUCT_OUT)/dt.img

define build-dtimage-target
    $(call pretty,"Target dt image: $(INSTALLED_DTIMAGE_TARGET)")
    $(hide) $(DTBTOOL) -o $@ -s $(BOARD_KERNEL_PAGESIZE) -p $(KERNEL_OUT)/scripts/dtc/ $(KERNEL_OUT)/arch/arm/boot/
    $(hide) chmod a+r $@
endef

$(INSTALLED_DTIMAGE_TARGET): $(DTBTOOL) $(INSTALLED_KERNEL_TARGET)
	$(build-dtimage-target)

ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_DTIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_DTIMAGE_TARGET)
endif


#----------------------------------------------------------------------
# Generate 1GB userdata image for 8930
#----------------------------------------------------------------------
ifeq ($(call is-board-platform-in-list,msm8960),true)

1G_USER_OUT := $(PRODUCT_OUT)/1g_user_image
BOARD_1G_USERDATAIMAGE_PARTITION_SIZE := 5368709120
INSTALLED_1G_USERDATAIMAGE_TARGET := $(1G_USER_OUT)/userdata.img

define build-1g-userdataimage-target
    $(call pretty,"Target 1G userdata fs image: $(INSTALLED_1G_USERDATAIMAGE_TARGET)")
    @mkdir -p $(1G_USER_OUT)
    $(hide) $(MKEXTUSERIMG) -s $(TARGET_OUT_DATA) $@ ext4 data $(BOARD_1G_USERDATAIMAGE_PARTITION_SIZE)
    $(hide) chmod a+r $@
    $(hide) $(call assert-max-image-size,$@,$(BOARD_1G_USERDATAIMAGE_PARTITION_SIZE),yaffs)
endef

$(INSTALLED_1G_USERDATAIMAGE_TARGET): $(INSTALLED_USERDATAIMAGE_TARGET)
	$(build-1g-userdataimage-target)

ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_1G_USERDATAIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_1G_USERDATAIMAGE_TARGET)

endif


#----------------------------------------------------------------------
# Generate NAND images
#----------------------------------------------------------------------
ifeq ($(call is-board-platform-in-list,msm7x27a msm7x30),true)

2K_NAND_OUT := $(PRODUCT_OUT)/2k_nand_images
4K_NAND_OUT := $(PRODUCT_OUT)/4k_nand_images
BCHECC_OUT := $(PRODUCT_OUT)/bchecc_images

INSTALLED_2K_BOOTIMAGE_TARGET := $(2K_NAND_OUT)/boot.img
INSTALLED_2K_SYSTEMIMAGE_TARGET := $(2K_NAND_OUT)/system.img
INSTALLED_2K_USERDATAIMAGE_TARGET := $(2K_NAND_OUT)/userdata.img
INSTALLED_2K_PERSISTIMAGE_TARGET := $(2K_NAND_OUT)/persist.img
INSTALLED_2K_RECOVERYIMAGE_TARGET := $(2K_NAND_OUT)/recovery.img

INSTALLED_4K_BOOTIMAGE_TARGET := $(4K_NAND_OUT)/boot.img
INSTALLED_4K_SYSTEMIMAGE_TARGET := $(4K_NAND_OUT)/system.img
INSTALLED_4K_USERDATAIMAGE_TARGET := $(4K_NAND_OUT)/userdata.img
INSTALLED_4K_PERSISTIMAGE_TARGET := $(4K_NAND_OUT)/persist.img
INSTALLED_4K_RECOVERYIMAGE_TARGET := $(4K_NAND_OUT)/recovery.img

INSTALLED_BCHECC_BOOTIMAGE_TARGET := $(BCHECC_OUT)/boot.img
INSTALLED_BCHECC_SYSTEMIMAGE_TARGET := $(BCHECC_OUT)/system.img
INSTALLED_BCHECC_USERDATAIMAGE_TARGET := $(BCHECC_OUT)/userdata.img
INSTALLED_BCHECC_PERSISTIMAGE_TARGET := $(BCHECC_OUT)/persist.img
INSTALLED_BCHECC_RECOVERYIMAGE_TARGET := $(BCHECC_OUT)/recovery.img

recovery_nand_fstab := $(TARGET_DEVICE_DIR)/recovery_nand.fstab

NAND_BOOTIMAGE_ARGS := \
	--kernel $(INSTALLED_KERNEL_TARGET) \
	--ramdisk $(INSTALLED_RAMDISK_TARGET) \
	--cmdline "$(BOARD_KERNEL_CMDLINE)" \
	--base $(BOARD_KERNEL_BASE)

NAND_RECOVERYIMAGE_ARGS := \
	--kernel $(INSTALLED_KERNEL_TARGET) \
	--ramdisk $(recovery_ramdisk) \
	--cmdline "$(BOARD_KERNEL_CMDLINE)" \
	--base $(BOARD_KERNEL_BASE)

INTERNAL_4K_BOOTIMAGE_ARGS := $(NAND_BOOTIMAGE_ARGS)
INTERNAL_4K_BOOTIMAGE_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

INTERNAL_2K_BOOTIMAGE_ARGS := $(NAND_BOOTIMAGE_ARGS)
INTERNAL_2K_BOOTIMAGE_ARGS += --pagesize $(BOARD_KERNEL_2KPAGESIZE)

INTERNAL_4K_MKYAFFS2_FLAGS := -c $(BOARD_KERNEL_PAGESIZE)
INTERNAL_4K_MKYAFFS2_FLAGS += -s $(BOARD_KERNEL_SPARESIZE)

INTERNAL_2K_MKYAFFS2_FLAGS := -c $(BOARD_KERNEL_2KPAGESIZE)
INTERNAL_2K_MKYAFFS2_FLAGS += -s $(BOARD_KERNEL_2KSPARESIZE)

INTERNAL_BCHECC_MKYAFFS2_FLAGS := -c $(BOARD_KERNEL_PAGESIZE)
INTERNAL_BCHECC_MKYAFFS2_FLAGS += -s $(BOARD_KERNEL_BCHECC_SPARESIZE)

INTERNAL_4K_RECOVERYIMAGE_ARGS := $(NAND_RECOVERYIMAGE_ARGS)
INTERNAL_4K_RECOVERYIMAGE_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

INTERNAL_2K_RECOVERYIMAGE_ARGS := $(NAND_RECOVERYIMAGE_ARGS)
INTERNAL_2K_RECOVERYIMAGE_ARGS += --pagesize $(BOARD_KERNEL_2KPAGESIZE)

# Generate boot image for NAND
ifeq ($(TARGET_BOOTIMG_SIGNED),true)

ifndef TARGET_SHA_TYPE
  TARGET_SHA_TYPE := sha256
endif

define build-nand-bootimage
	@echo "target NAND boot image: $(3)"
	$(hide) mkdir -p $(1)
	$(hide) $(MKBOOTIMG) $(2) --output $(3).nonsecure
	$(hide) openssl dgst -$(TARGET_SHA_TYPE)  -binary $(3).nonsecure > $(3).$(TARGET_SHA_TYPE)
	$(hide) openssl rsautl -sign -in $(3).$(TARGET_SHA_TYPE) -inkey $(PRODUCT_PRIVATE_KEY) -out $(3).sig
	$(hide) dd if=/dev/zero of=$(3).sig.padded bs=$(BOARD_KERNEL_PAGESIZE) count=1
	$(hide) dd if=$(3).sig of=$(3).sig.padded conv=notrunc
	$(hide) cat $(3).nonsecure $(3).sig.padded > $(3)
	$(hide) rm -rf $(3).$(TARGET_SHA_TYPE) $(3).sig $(3).sig.padded
endef
else
define build-nand-bootimage
	@echo "target NAND boot image: $(3)"
	$(hide) mkdir -p $(1)
	$(hide) $(MKBOOTIMG) $(2) --output $(3)
endef
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE),raw)
endif

# Generate system image for NAND
define build-nand-systemimage
  @echo "target NAND system image: $(3)"
  $(hide) mkdir -p $(1)
  $(hide) $(MKYAFFS2) -f $(2) $(TARGET_OUT) $(3)
  $(hide) chmod a+r $(3)
  $(hide) $(call assert-max-image-size,$@,$(BOARD_SYSTEMIMAGE_PARTITION_SIZE),yaffs)
endef

# Generate userdata image for NAND
define build-nand-userdataimage
  @echo "target NAND userdata image: $(3)"
  $(hide) mkdir -p $(1)
  $(hide) $(MKYAFFS2) -f $(2) $(TARGET_OUT_DATA) $(3)
  $(hide) chmod a+r $(3)
  $(hide) $(call assert-max-image-size,$@,$(BOARD_USERDATAIMAGE_PARTITION_SIZE),yaffs)
endef

# Generate persist image for NAND
define build-nand-persistimage
  @echo "target NAND persist image: $(3)"
  $(hide) mkdir -p $(1)
  $(hide) $(MKYAFFS2) -f $(2) $(TARGET_OUT_PERSIST) $(3)
  $(hide) chmod a+r $(3)
  $(hide) $(call assert-max-image-size,$@,$(BOARD_PERSISTIMAGE_PARTITION_SIZE),yaffs)
endef

$(INSTALLED_4K_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INSTALLED_BOOTIMAGE_TARGET)
	$(hide) $(call build-nand-bootimage,$(4K_NAND_OUT),$(INTERNAL_4K_BOOTIMAGE_ARGS),$(INSTALLED_4K_BOOTIMAGE_TARGET))
ifeq ($(call is-board-platform,msm7x27a),true)
	$(hide) $(call build-nand-bootimage,$(2K_NAND_OUT),$(INTERNAL_2K_BOOTIMAGE_ARGS),$(INSTALLED_2K_BOOTIMAGE_TARGET))
	$(hide) $(call build-nand-bootimage,$(BCHECC_OUT),$(INTERNAL_4K_BOOTIMAGE_ARGS),$(INSTALLED_BCHECC_BOOTIMAGE_TARGET))
endif # is-board-platform

$(INSTALLED_4K_SYSTEMIMAGE_TARGET): $(MKYAFFS2) $(INSTALLED_SYSTEMIMAGE)
	$(hide) $(call build-nand-systemimage,$(4K_NAND_OUT),$(INTERNAL_4K_MKYAFFS2_FLAGS),$(INSTALLED_4K_SYSTEMIMAGE_TARGET))
ifeq ($(call is-board-platform,msm7x27a),true)
	$(hide) $(call build-nand-systemimage,$(2K_NAND_OUT),$(INTERNAL_2K_MKYAFFS2_FLAGS),$(INSTALLED_2K_SYSTEMIMAGE_TARGET))
	$(hide) $(call build-nand-systemimage,$(BCHECC_OUT),$(INTERNAL_BCHECC_MKYAFFS2_FLAGS),$(INSTALLED_BCHECC_SYSTEMIMAGE_TARGET))
endif # is-board-platform

$(INSTALLED_4K_USERDATAIMAGE_TARGET): $(MKYAFFS2) $(INSTALLED_USERDATAIMAGE_TARGET)
	$(hide) $(call build-nand-userdataimage,$(4K_NAND_OUT),$(INTERNAL_4K_MKYAFFS2_FLAGS),$(INSTALLED_4K_USERDATAIMAGE_TARGET))
ifeq ($(call is-board-platform,msm7x27a),true)
	$(hide) $(call build-nand-userdataimage,$(2K_NAND_OUT),$(INTERNAL_2K_MKYAFFS2_FLAGS),$(INSTALLED_2K_USERDATAIMAGE_TARGET))
	$(hide) $(call build-nand-userdataimage,$(BCHECC_OUT),$(INTERNAL_BCHECC_MKYAFFS2_FLAGS),$(INSTALLED_BCHECC_USERDATAIMAGE_TARGET))
endif # is-board-platform

$(INSTALLED_4K_PERSISTIMAGE_TARGET): $(MKYAFFS2) $(INSTALLED_PERSISTIMAGE_TARGET)
	$(hide) $(call build-nand-persistimage,$(4K_NAND_OUT),$(INTERNAL_4K_MKYAFFS2_FLAGS),$(INSTALLED_4K_PERSISTIMAGE_TARGET))
ifeq ($(call is-board-platform,msm7x27a),true)
	$(hide) $(call build-nand-persistimage,$(2K_NAND_OUT),$(INTERNAL_2K_MKYAFFS2_FLAGS),$(INSTALLED_2K_PERSISTIMAGE_TARGET))
	$(hide) $(call build-nand-persistimage,$(BCHECC_OUT),$(INTERNAL_BCHECC_MKYAFFS2_FLAGS),$(INSTALLED_BCHECC_PERSISTIMAGE_TARGET))
endif # is-board-platform

$(INSTALLED_4K_RECOVERYIMAGE_TARGET): $(MKBOOTIMG) $(INSTALLED_RECOVERYIMAGE_TARGET) $(recovery_nand_fstab)
	$(hide) cp -f $(recovery_nand_fstab) $(TARGET_RECOVERY_ROOT_OUT)/etc
	$(MKBOOTFS) $(TARGET_RECOVERY_ROOT_OUT) | $(MINIGZIP) > $(recovery_ramdisk)
	$(hide) $(call build-nand-bootimage,$(4K_NAND_OUT),$(INTERNAL_4K_RECOVERYIMAGE_ARGS),$(INSTALLED_4K_RECOVERYIMAGE_TARGET))
ifeq ($(call is-board-platform,msm7x27a),true)
	$(hide) $(call build-nand-bootimage,$(2K_NAND_OUT),$(INTERNAL_2K_RECOVERYIMAGE_ARGS),$(INSTALLED_2K_RECOVERYIMAGE_TARGET))
	$(hide) $(call build-nand-bootimage,$(BCHECC_OUT),$(INTERNAL_4K_RECOVERYIMAGE_ARGS),$(INSTALLED_BCHECC_RECOVERYIMAGE_TARGET))
endif # is-board-platform

ALL_DEFAULT_INSTALLED_MODULES += \
	$(INSTALLED_4K_BOOTIMAGE_TARGET) \
	$(INSTALLED_4K_SYSTEMIMAGE_TARGET) \
	$(INSTALLED_4K_USERDATAIMAGE_TARGET) \
	$(INSTALLED_4K_PERSISTIMAGE_TARGET)

ALL_MODULES.$(LOCAL_MODULE).INSTALLED += \
	$(INSTALLED_4K_BOOTIMAGE_TARGET) \
	$(INSTALLED_4K_SYSTEMIMAGE_TARGET) \
	$(INSTALLED_4K_USERDATAIMAGE_TARGET) \
	$(INSTALLED_4K_PERSISTIMAGE_TARGET)

ifneq ($(BUILD_TINY_ANDROID),true)
ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_4K_RECOVERYIMAGE_TARGET)
ALL_MODULES.$(LOCAL_MODULE).INSTALLED += $(INSTALLED_4K_RECOVERYIMAGE_TARGET)
endif # !BUILD_TINY_ANDROID

endif # is-board-platform-in-list

.PHONY: aboot
aboot: $(INSTALLED_BOOTLOADER_MODULE)

.PHONY: kernel
kernel: $(INSTALLED_BOOTIMAGE_TARGET) $(INSTALLED_SEC_BOOTIMAGE_TARGET) $(INSTALLED_4K_BOOTIMAGE_TARGET)

.PHONY: recoveryimage
recoveryimage: $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_SEC_RECOVERYIMAGE_TARGET) $(INSTALLED_4K_RECOVERYIMAGE_TARGET)

.PHONY: persistimage
persistimage: $(INSTALLED_PERSISTIMAGE_TARGET) $(INSTALLED_4K_PERSISTIMAGE_TARGET)
