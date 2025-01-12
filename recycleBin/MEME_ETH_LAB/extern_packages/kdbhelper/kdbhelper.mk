KDBHELPER_VERSION:= 1.0.0
KDBHELPER_SITE:= $(TOPDIR)/../extern_packages/kdbhelper/src
KDBHELPER_SITE_METHOD:=local

$(eval $(kernel-module))
$(eval $(generic-package))
