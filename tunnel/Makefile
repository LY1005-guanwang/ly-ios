TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LyTunnel

LyTunnel_BUNDLE_EXTENSION = appex
LyTunnel_FILES = LyTunnel.swift
LyTunnel_FRAMEWORKS = Foundation NetworkExtension
LyTunnel_INSTALL_PATH = /Applications/LyInternal.app/PlugIns
LyTunnel_RESOURCE_DIRS = ../Resources
LyTunnel_INFO_PLIST = ../Resources/tunnel-Info.plist
LyTunnel_CODESIGN_FLAGS = -S../ly_internal.entitlements

include $(THEOS_MAKE_PATH)/bundle.mk