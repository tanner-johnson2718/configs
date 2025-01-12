HELLOMOD_VERSION = 1.0
HELLOMOD_SITE = $(TOPDIR)/../extern_packages/hellomod/src
HELLOMOD_SITE_METHOD = local

$(eval $(kernel-module))
$(eval $(generic-package))