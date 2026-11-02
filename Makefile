TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LyInternal

LyInternal_FILES = $(wildcard Sources/*.swift) $(wildcard Sources/*.c)
LyInternal_FRAMEWORKS = UIKit Foundation NetworkExtension Security CryptoKit
LyInternal_SWIFT_BRIDGING_HEADER = Sources/LyInternal-Bridging-Header.h
LyInternal_CFLAGS = -O2 -fvisibility=hidden
LyInternal_LDFLAGS = -Xlinker -dead_strip -Xlinker -S
LyInternal_CODESIGN_FLAGS = -Sly_internal.entitlements
LyInternal_INSTALL_PATH = /Applications
LyInternal_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk