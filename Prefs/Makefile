include theos/makefiles/common.mk

BUNDLE_NAME = UpdateHideriOS5Prefs
UpdateHideriOS5Prefs_FILES = AppCell.m LoadingCell.m IconImageDownloader.m Update.m UpdateHideriOS5Prefs.mm 
UpdateHideriOS5Prefs_INSTALL_PATH = /Library/PreferenceBundles
UpdateHideriOS5Prefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
UpdateHideriOS5Prefs_PRIVATE_FRAMEWORKS = Preferences StoreServices iTunesStore iTunesStoreUI
DEBUG = 1

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)

