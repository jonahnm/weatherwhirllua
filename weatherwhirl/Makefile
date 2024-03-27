THEOS_DEVICE_IP = 10.10.10.170
TARGET := iphone:clang:16.5:14.3
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless
ifdef ROOTFUL
$(shell test -f controlrootful && mv control controlrootless)
$(shell test -f controlrootful && mv controlrootful control)
THEOS_PACKAGE_SCHEME = rootful
else
$(shell test -f controlrootless && mv control controlrootful)
$(shell test -f controlrootless && mv controlrootless control)
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeatherWhirl

WeatherWhirl_FILES = Tweak.m ../lfs/src/lfs.c
WeatherWhirl_CFLAGS = -fobjc-arc -I/usr/local/include -I/opt/homebrew/include -Wno-unused-variable -Wno-unused-function
WeatherWhirl_LDFLAGS += -Llayout/usr/lib -L$(THEOS)/vendor/lib
WeatherWhirl_LIBRARIES = luajit
include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += weatherwhirlprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
