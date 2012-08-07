# The try-run, cc-version, cc-ifversion and cc-option macros are inspired
# by the Linux kernel build system's versions of the macros with the same
# name.
#
# The implementations here are rewritten to avoid license clashes, and
# they're a lot simpler than their kernel counterparts because, at least
# for now, we don't need to support all the compilers the kernel supports,
# and we don't need to be aware of all the details the kernel checks for.
#
# Usage examples:
#      echo "GCC version $(cc-version)" [e.g. 46 for 4.6]
#      echo $(call cc-ifversion, -lt, 46, GCC older than 4.6)
#      # Use -mcpu=cortex-a9 if supported, otherwise -mcpu=cortex-a8
#      echo $(call cc-option, -mcpu=cortex-a9, -mcpu=cortex-a8)
#      # Use -mcpu=cortex-a9 if supported, otherwise -mcpu=cortex-a8
#      # if supported, otherwise nothing
#      echo $(call cc-option, -mcpu=cortex-a9, $(call cc-option, -mcpu=cortex-a8))
#

# We have to do our own version of setting TARGET_CC because we can be
# included before TARGET_CC is set, but we may want to use cc-option and
# friends in the same file that sets TARGET_CC...

ifeq ($(strip $(TARGET_TOOLS_PREFIX)),)
LINARO_COMPILERCHECK_CC := prebuilts/gcc/$(HOST_PREBUILT_TAG)/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-gcc$(HOST_EXECUTABLE_SUFFIX)
else
LINARO_COMPILERCHECK_CC := $(TARGET_TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
endif

try-run = $(shell set -e; \
	if ($(1)) >/dev/null 2>&1; then \
		echo "$(2)"; \
	else \
		echo "$(3)"; \
	fi)

cc-version = $(shell echo '__GNUC__ __GNUC_MINOR__' \
	|$(LINARO_COMPILERCHECK_CC) -E -xc - |tail -n1 |sed -e 's, ,,g')

cc-ifversion = $(shell [ $(call cc-version) $(1) $(2) ] && echo $(3))

cc-option = $(call try-run, echo -e "$(1)" \
	|$(LINARO_COMPILERCHECK_CC) $(1) -c -xc /dev/null -o /dev/null,$(1),$(2))
