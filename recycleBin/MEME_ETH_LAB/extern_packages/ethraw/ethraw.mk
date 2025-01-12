ETHRAW_VERSION:= 1.0.0
ETHRAW_SITE:= $(TOPDIR)/../$(EXTERNAL_PACKAGES_DIR)/ethraw/src
ETHRAW_SITE_METHOD:=local
ETHRAW_INSTALL_TARGET:=YES

define ETHRAW_BUILD_CMDS
    $(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define ETHRAW_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/sniff $(TARGET_DIR)/bin
    $(INSTALL) -D -m 0755 $(@D)/gen $(TARGET_DIR)/bin
endef

define ETHRAW_PERMISSIONS
    /bin/sniff f 4755 0 0 - - - - - 
    /bin/gen f 4755 0 0 - - - - - 
endef

$(eval $(generic-package))
