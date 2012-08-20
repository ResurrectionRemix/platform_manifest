# vars for use by utils
empty :=
space := $(empty) $(empty)
colon := $(empty):$(empty)
underscore := $(empty)_$(empty)

# $(call match-word,w1,w2)
# checks if w1 == w2
# How it works
#   if (w1-w2 not empty or w2-w1 not empty) then not_match else match
#
# returns true or empty
#$(warning :$(1): :$(2): :$(subst $(1),,$(2)):) \
#$(warning :$(2): :$(1): :$(subst $(2),,$(1)):) \
#
define match-word
$(strip \
  $(if $(or $(subst $(1),$(empty),$(2)),$(subst $(2),$(empty),$(1))),,true) \
)
endef

# $(call find-word-in-list,w,wlist)
# finds an exact match of word w in word list wlist
#
# How it works
#   fill wlist spaces with colon
#   wrap w with colon
#   search word w in list wl, if found match m, return stripped word w
#
# returns stripped word or empty
define find-word-in-list
$(strip \
  $(eval wl:= $(colon)$(subst $(space),$(colon),$(strip $(2)))$(colon)) \
  $(eval w:= $(colon)$(strip $(1))$(colon)) \
  $(eval m:= $(findstring $(w),$(wl))) \
  $(if $(m),$(1),) \
)
endef

# $(call match-word-in-list,w,wlist)
# does an exact match of word w in word list wlist
# How it works
#   if the input word is not empty
#     return output of an exact match of word w in wordlist wlist
#   else
#     return empty
# returns true or empty
define match-word-in-list
$(strip \
  $(if $(strip $(1)), \
    $(call match-word,$(call find-word-in-list,$(1),$(2)),$(strip $(1))), \
  ) \
)
endef

# $(call match-prefix,p,delim,w/wlist)
# matches prefix p in wlist using delimiter delim
#
# How it works
#   trim the words in wlist w
#   if find-word-in-list returns not empty
#     return true
#   else
#     return empty
#
define match-prefix
$(strip \
  $(eval w := $(strip $(1)$(strip $(2)))) \
  $(eval text := $(patsubst $(w)%,$(1),$(3))) \
  $(if $(call match-word-in-list,$(1),$(text)),true,) \
)
endef

# ----
# The following utilities are meant for board platform specific
# featurisation

# $(call get-vendor-board-platforms,v)
# returns list of board platforms for vendor v
define get-vendor-board-platforms
$($(1)_BOARD_PLATFORMS)
endef

# $(call is-board-platform,bp)
# returns true or empty
define is-board-platform
$(call match-word,$(1),$(TARGET_BOARD_PLATFORM))
endef

# $(call is-not-board-platform,bp)
# returns true or empty
define is-not-board-platform
$(if $(call match-word,$(1),$(TARGET_BOARD_PLATFORM)),,true)
endef

# $(call is-board-platform-in-list,bpl)
# returns true or empty
define is-board-platform-in-list
$(call match-word-in-list,$(TARGET_BOARD_PLATFORM),$(1))
endef

# $(call is-vendor-board-platform,vendor)
# returns true or empty
define is-vendor-board-platform
$(strip \
  $(call match-word-in-list,$(TARGET_BOARD_PLATFORM),\
    $(call get-vendor-board-platforms,$(1)) \
  ) \
)
endef

# $(call is-chipset-in-board-platform,chipset)
# does a prefix match of chipset in TARGET_BOARD_PLATFORM
# uses underscore as a delimiter
#
# returns true or empty
define is-chipset-in-board-platform
$(call match-prefix,$(1),$(underscore),$(TARGET_BOARD_PLATFORM))
endef

# $(call is-chipset-prefix-in-board-platform,prefix)
# does a chipset prefix match in TARGET_BOARD_PLATFORM
# assumes '_' and 'a' as the delimiter to the chipset prefix
#
# How it works
#   if ($(prefix)_ or $(prefix)a match in board platform)
#     return true
#   else
#     return empty
#
define is-chipset-prefix-in-board-platform
$(strip \
  $(eval delim_a := $(empty)a$(empty)) \
  $(if \
    $(or \
      $(call match-prefix,$(1),$(delim_a),$(TARGET_BOARD_PLATFORM)), \
      $(call match-prefix,$(1),$(underscore),$(TARGET_BOARD_PLATFORM)), \
    ), \
    true, \
  ) \
)
endef

#----
# The following utilities are meant for Android Code Name
# specific featurisation
#
# refer http://source.android.com/source/build-numbers.html
# for code names and associated sdk versions
CUPCAKE_SDK_VERSIONS := 3
DONUT_SDK_VERSIONS   := 4
ECLAIR_SDK_VERSIONS  := 5 6 7
FROYO_SDK_VERSIONS   := 8
GINGERBREAD_SDK_VERSIONS := 9 10
HONEYCOMB_SDK_VERSIONS := 11 12 13
ICECREAM_SANDWICH_SDK_VERSIONS := 14 15
JELLY_BEAN_SDK_VERSIONS := 16

# $(call is-android-codename,codename)
# codename is one of cupcake,donut,eclair,froyo,gingerbread,icecream
# please refer the $(codename)_SDK_VERSIONS declared above
define is-android-codename
$(strip \
  $(if \
    $(call match-word-in-list,$(PLATFORM_SDK_VERSION),$($(1)_SDK_VERSIONS)), \
    true, \
  ) \
)
endef

# $(call is-android-codename-in-list,cnlist)
# cnlist is combination/list of android codenames
define is-android-codename-in-list
$(strip \
  $(eval acn := $(empty)) \
    $(foreach \
      i,$(1),\
      $(eval acn += \
        $(if \
          $(call \
            match-word-in-list,\
            $(PLATFORM_SDK_VERSION),\
            $($(i)_SDK_VERSIONS)\
          ),\
          true,\
        )\
      )\
    ) \
  $(if $(strip $(acn)),true,) \
)
endef
