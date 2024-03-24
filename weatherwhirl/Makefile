THEOS_DEVICE_IP = 10.10.10.170
TARGET := iphone:clang:16.5:14.3
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeatherWhirl

WeatherWhirl_FILES = Tweak.m ../lfs/src/lfs.c
WeatherWhirl_CFLAGS = -fobjc-arc -I/usr/local/include -Wno-unused-variable -Wno-unused-function
WeatherWhirl_LDFLAGS += -Llib
WeatherWhirl_LIBRARIES = luajit curl
include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += weatherwhirlprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
