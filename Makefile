TWEAK_NAME = ClassicRetweet
ClassicRetweet_FILES = Tweak.x

export TARGET = iphone:clang
export ARCHS = armv7 armv7s arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_armv7s = 6.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden
export INSTALL_TARGET_PROCESSES = Twitter

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
