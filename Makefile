export THEOS_DEVICE_IP=10.69.192.188
include theos/makefiles/common.mk

LIBRARY_NAME = UpdateHideriOS5
UpdateHideriOS5_FILES = Tweak.xm
UpdateHideriOS5_FRAMEWORKS = UIKit
UpdateHideriOS5_LDFLAGS = -lsubstrate
UpdateHideriOS5_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
SUBPROJECTS = Prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/library.mk

after-install::
	-rm *.deb
	-install.exec "killall AppStore"
	-install.exec "killall Preferences"
	-install.exec "killall itunesstored"
