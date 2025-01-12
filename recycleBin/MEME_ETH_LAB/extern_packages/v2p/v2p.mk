V2P_VERSION:= 1.0.0
V2P_SITE:= $(TOPDIR)/../extern_packages/v2p/src
V2P_SITE_METHOD:=local

$(eval $(kernel-module))
$(eval $(generic-package))
