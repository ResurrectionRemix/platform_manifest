# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
TARGET_ARCH_VARIANT_FPU := neon
include $(BUILD_COMBOS)/arch/$(TARGET_ARCH)/armv7-a.mk
