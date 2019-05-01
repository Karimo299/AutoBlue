ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoBlue
AutoBlue_FILES = Tweak.xm
AutoBlue_EXTRA_FRAMEWORKS += Cephei
AutoBlue_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += autobluepref
SUBPROJECTS += AutoBlueiOS10
include $(THEOS_MAKE_PATH)/aggregate.mk
