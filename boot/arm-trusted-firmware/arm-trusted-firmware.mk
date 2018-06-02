################################################################################
#
# arm-trusted-firmware
#
################################################################################

ARM_TRUSTED_FIRMWARE_VERSION = 
ARM_TRUSTED_FIRMWARE_LICENSE = BSD-3-Clause
ARM_TRUSTED_FIRMWARE_LICENSE_FILES = license.rst

ARM_TRUSTED_FIRMWARE_SITE = "${BR2_EXTERNAL_cambricon_buildroot_PATH}/package/arm-trusted-firmware"
ARM_TRUSTED_FIRMWARE_SITE_METHOD = local

ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES = YES

ARM_TRUSTED_FIRMWARE_PLATFORM = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_PLATFORM))

ARM_TRUSTED_FIRMWARE_MAKE_OPTS += \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES)) \
	ARCH=aarch64								\
	PLAT=$(ARM_TRUSTED_FIRMWARE_PLATFORM)

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_AS_BL33),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += BL33=$(BINARIES_DIR)/u-boot.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += uboot
endif


ARM_TRUSTED_FIRMWARE_MAKE_TARGETS = all

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_FIP),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += fip
#ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-openssl
# fiptool only exists in newer (>= 1.3) versions of ATF, so we build
# it conditionally. We need to explicitly build it as it requires
# OpenSSL, and therefore needs to be passed proper variables to find
# the host OpenSSL.
define ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL
	if test -d $(@D)/tools/fiptool; then \
		$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/tools/fiptool \
			$(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
			CPPFLAGS="$(HOST_CPPFLAGS)" \
			LDLIBS="$(HOST_LDFLAGS) -lcrypto" ; \
	fi
endef
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += bl31
endif

define ARM_TRUSTED_FIRMWARE_BUILD_CMDS
	$(ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL)
	$(TARGET_CONFIGURE_OPTS) \
		$(MAKE) -C $(@D) $(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
			$(ARM_TRUSTED_FIRMWARE_MAKE_TARGETS)
endef

define ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES_CMDS
	cp -dpf $(@D)/build/$(ARM_TRUSTED_FIRMWARE_PLATFORM)/release/*.bin $(BINARIES_DIR)/
endef


$(eval $(generic-package))
