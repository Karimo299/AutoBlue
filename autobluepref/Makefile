include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AutoBluePref
AutoBluePref_FILES = ABTRootListController.m
AutoBluePref_INSTALL_PATH = /Library/PreferenceBundles
AutoBluePref_FRAMEWORKS = UIKit
AutoBluePref_EXTRA_FRAMEWORKS += CepheiPrefs
AutoBluePref_LIBRARIES = applist
AutoBluePref_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AutoBluePref.plist$(ECHO_END)
