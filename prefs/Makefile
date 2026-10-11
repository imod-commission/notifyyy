export THEOS_PACKAGE_SCHEME = roothide
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = notifyyy
notifyyy_FILES = NOTYRootListController.m
notifyyy_FRAMEWORKS = UIKit
notifyyy_PRIVATE_FRAMEWORKS = Preferences
notifyyy_INSTALL_PATH = /Library/PreferenceBundles
notifyyy_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk