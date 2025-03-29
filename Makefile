#
# Copyright (c) 2018-2023 Nick Peng (pymumu@gmail.com)
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=smartdns
PKG_VERSION:=1.2025.46.2
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://www.github.com/pymumu/smartdns.git
PKG_SOURCE_VERSION:=361dc7e34ac418544c8006927161563b325ab97f
PKG_MIRROR_HASH:=77f7e2d992b7c5917c75d38ca29f6f90efd58e88f29a1f19cca51cb28cbe92cb

SMARTDNS_WEBUI_VERSION:=1.0.0
SMAETDNS_WEBUI_SOURCE_PROTO:=git
SMARTDNS_WEBUI_SOURCE_URL:=https://github.com/pymumu/smartdns-webui.git
SMARTDNS_WEBUI_SOURCE_VERSION:=7bbd1a6f6a7038ecb6cfbf424615aa7831bc1cea
SMARTDNS_WEBUI_HASH:=b3f4f73b746ee169708f6504c52b33d9bbeb7c269b731bd7de4f61d0ad212d74
SMARTDNS_WEBUI_FILE:=smartdns-webui-$(SMARTDNS_WEBUI_VERSION).tar.gz

PKG_MAINTAINER:=Nick Peng <pymumu@gmail.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1

ifdef CONFIG_PACKAGE_smartdns-ui
PKG_BUILD_DEPENDS:=rust/host node/host
include ../../lang/rust/rust-package.mk
endif

include $(INCLUDE_DIR)/package.mk

MAKE_VARS += VER=$(PKG_VERSION) 
MAKE_PATH:=src

define Package/smartdns/default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  URL:=https://www.github.com/pymumu/smartdns/
endef

define Package/smartdns
  $(Package/smartdns/default)
  TITLE:=smartdns server
  DEPENDS:=+libpthread +libopenssl
endef

define Package/smartdns/description
SmartDNS is a local DNS server which accepts DNS query requests from local network clients,
gets DNS query results from multiple upstream DNS servers concurrently, and returns the fastest IP to clients.
Unlike dnsmasq's all-servers, smartdns returns the fastest IP, and encrypt DNS queries with DoT or DoH. 
endef

define Package/smartdns/conffiles
/etc/config/smartdns
/etc/smartdns/address.conf
/etc/smartdns/blacklist-ip.conf
/etc/smartdns/custom.conf
/etc/smartdns/domain-block.list
/etc/smartdns/domain-forwarding.list
endef

define Package/smartdns/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d 
	$(INSTALL_DIR) $(1)/etc/smartdns $(1)/etc/smartdns/domain-set $(1)/etc/smartdns/conf.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/smartdns $(1)/usr/sbin/smartdns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/package/openwrt/files/etc/init.d/smartdns $(1)/etc/init.d/smartdns
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/address.conf $(1)/etc/smartdns/address.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/blacklist-ip.conf $(1)/etc/smartdns/blacklist-ip.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/custom.conf $(1)/etc/smartdns/custom.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/files/etc/config/smartdns $(1)/etc/config/smartdns
endef

define Package/smartdns-ui
  $(Package/smartdns/default)
  TITLE:=smartdns dashboard
  DEPENDS:=+smartdns
endef

define Package/smartdns-ui/description
A dashboard ui for smartdns server.
endef

define Package/smartdns-ui/conffiles
/etc/config/smartdns
endef

define Package/smartdns-ui/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/etc/smartdns/conf.d/
	$(INSTALL_DIR) $(1)/usr/share/smartdns/wwwroot
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/plugin/smartdns-ui/target/libsmartdns_ui.so $(1)/usr/lib/libsmartdns_ui.so
	$(CP) $(PKG_BUILD_DIR)/smartdns-webui/out/* $(1)/usr/share/smartdns/wwwroot
endef

define Build/Compile/smartdns-webui
	npm install --prefix $(PKG_BUILD_DIR)/smartdns-webui/
	npm run build --prefix $(PKG_BUILD_DIR)/smartdns-webui/
endef

define Build/Compile/smartdns-ui
	CARGO_BUILD_ARGS="$(if $(strip $(RUST_PKG_FEATURES)),--features "$(strip $(RUST_PKG_FEATURES))") --profile $(CARGO_PKG_PROFILE)"
	+$(CARGO_PKG_VARS) CARGO_BUILD_ARGS="$(CARGO_BUILD_ARGS)" CC=$(TARGET_CC) \
	make -C $(PKG_BUILD_DIR)/plugin/smartdns-ui
endef

define Download/smartdns-webui
	FILE:=$(SMARTDNS_WEBUI_FILE)
	PROTO:=$(SMAETDNS_WEBUI_SOURCE_PROTO)
	URL:=$(SMARTDNS_WEBUI_SOURCE_URL)
	MIRROR_HASH:=b3f4f73b746ee169708f6504c52b33d9bbeb7c269b731bd7de4f61d0ad212d74
	VERSION:=$(SMARTDNS_WEBUI_SOURCE_VERSION)
	HASH:=$(SMARTDNS_WEBUI_HASH)
	SUBDIR:=smartdns-webui
endef
$(eval $(call Download,smartdns-webui))

ifdef CONFIG_PACKAGE_smartdns-ui
define Build/Prepare
	$(call Build/Prepare/Default)
	$(TAR) -C $(PKG_BUILD_DIR)/ -xf $(DL_DIR)/$(SMARTDNS_WEBUI_FILE)
endef
endif

define Build/Compile
	$(call Build/Compile/Default,smartdns)
ifdef CONFIG_PACKAGE_smartdns-ui
	$(call Build/Compile/smartdns-webui)
	$(call Build/Compile/smartdns-ui)
endif
endef

$(eval $(call BuildPackage,smartdns))
$(eval $(call BuildPackage,smartdns-ui))

