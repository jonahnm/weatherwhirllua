ARCHS = arm64 arm64e
TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk
BUNDLE_NAME = WeatherWhirlPrefs

WeatherWhirlPrefs_FRAMEWORKS = SwiftUI
WeatherWhirlPrefs_FILES = $(shell find Sources/WeatherWhirlPrefs -name '*.swift') $(shell find Sources/WeatherWhirlPrefsC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
WeatherWhirlPrefs_SWIFTFLAGS = -ISources/WeatherWhirlPrefsC/include 
ifndef ROOTFUL
THEOS_PACKAGE_SCHEME = rootless
endif
WeatherWhirlPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeatherWhirlPrefs_CFLAGS = -fobjc-arc
WeatherWhirlPrefs_LDFLAGS += -L$(THEOS)/vendor/lib  -F../lib
WeatherWhirlPrefs_EXTRA_FRAMEWORKS = Comet
include $(THEOS_MAKE_PATH)/bundle.mk
after-all:: $(eval SHELL:=/bin/zsh)
	if [[ ! -v ROOTFUL ]]; then \
		install_name_tool -change "/Library/Frameworks/Comet.framework/Comet" "/var/jb/Library/Frameworks/Comet.framework/Comet" "../.theos/obj/debug/WeatherWhirlPrefs.bundle/WeatherWhirlPrefs"; \
		ldid -S "../.theos/obj/debug/WeatherWhirlPrefs.bundle/WeatherWhirlPrefs"; \
	fi
