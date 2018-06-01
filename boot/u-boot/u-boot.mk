################################################################################
#
# uboot
#
################################################################################

UBOOT_VERSION =

UBOOT_LICENSE = GPL-2.0+
UBOOT_LICENSE_FILES = Licenses/gpl-2.0.txt

UBOOT_INSTALL_IMAGES = YES

UBOOT_SITE = "${BR2_EXTERNAL_cambricon_buildroot_PATH}/package/u-boot"
UBOOT_SITE_METHOD = local

ifeq ($(BR2_TARGET_UBOOT_FORMAT_BIN),y)
UBOOT_BINS += u-boot.bin
endif

ifeq ($(BR2_TARGET_UBOOT_FORMAT_ELF),y)
UBOOT_BINS += u-boot
# To make elf usable for debuging on ARC use special target
ifeq ($(BR2_arc),y)
UBOOT_MAKE_TARGET += mdbtrick
endif
endif

# Call 'make all' unconditionally
UBOOT_MAKE_TARGET += all

ifeq ($(BR2_TARGET_UBOOT_FORMAT_DTB_IMG),y)
UBOOT_BINS += u-boot-dtb.img
UBOOT_MAKE_TARGET += u-boot-dtb.img
endif

ifeq ($(BR2_TARGET_UBOOT_FORMAT_DTB_BIN),y)
UBOOT_BINS += u-boot-dtb.bin
UBOOT_MAKE_TARGET += u-boot-dtb.bin
endif

ifeq ($(BR2_TARGET_UBOOT_FORMAT_IMG),y)
UBOOT_BINS += u-boot.img
UBOOT_MAKE_TARGET += u-boot.img
endif


# The kernel calls AArch64 'arm64', but U-Boot calls it just 'arm', so
# we have to special case it. Similar for i386/x86_64 -> x86
ifeq ($(KERNEL_ARCH),arm64)
UBOOT_ARCH = arm
else ifneq ($(filter $(KERNEL_ARCH),i386 x86_64),)
UBOOT_ARCH = x86
else
UBOOT_ARCH = $(KERNEL_ARCH)
endif

UBOOT_MAKE_OPTS += \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	ARCH=$(UBOOT_ARCH) \
	HOSTCC="$(HOSTCC) $(subst -I/,-isystem /,$(subst -I /,-isystem /,$(HOST_CFLAGS)))" \
	HOSTLDFLAGS="$(HOST_LDFLAGS)"

ifeq ($(BR2_TARGET_UBOOT_NEEDS_DTC),y)
UBOOT_DEPENDENCIES += host-dtc
endif

# prior to u-boot 2013.10 the license info was in COPYING. Copy it so
# legal-info finds it
define UBOOT_COPY_OLD_LICENSE_FILE
	if [ -f $(@D)/COPYING ]; then \
		$(INSTALL) -m 0644 -D $(@D)/COPYING $(@D)/Licenses/gpl-2.0.txt; \
	fi
endef

UBOOT_POST_EXTRACT_HOOKS += UBOOT_COPY_OLD_LICENSE_FILE
UBOOT_POST_RSYNC_HOOKS += UBOOT_COPY_OLD_LICENSE_FILE


# This is equivalent to upstream commit
# http://git.denx.de/?p=u-boot.git;a=commitdiff;h=e0d20dc1521e74b82dbd69be53a048847798a90a. It
# fixes a build failure when libfdt-devel is installed system-wide.
# This only works when scripts/dtc/libfdt exists (E.G. versions containing
# http://git.denx.de/?p=u-boot.git;a=commitdiff;h=c0e032e0090d6541549b19cc47e06ccd1f302893)
define UBOOT_FIXUP_LIBFDT_INCLUDE
	if [ -d $(@D)/scripts/dtc/libfdt ]; then \
		$(SED) 's%-I$$(srctree)/lib/libfdt%-I$$(srctree)/scripts/dtc/libfdt%' $(@D)/tools/Makefile; \
	fi
endef
UBOOT_POST_PATCH_HOOKS += UBOOT_FIXUP_LIBFDT_INCLUDE

ifeq ($(BR2_TARGET_UBOOT_USE_DEFCONFIG),y)
UBOOT_KCONFIG_DEFCONFIG = $(call qstrip,$(BR2_TARGET_UBOOT_BOARD_DEFCONFIG))_defconfig
else ifeq ($(BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG),y)
UBOOT_KCONFIG_FILE = $(call qstrip,$(BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE))
endif # BR2_TARGET_UBOOT_USE_DEFCONFIG

UBOOT_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig
UBOOT_KCONFIG_OPTS = $(UBOOT_MAKE_OPTS)
define UBOOT_HELP_CMDS
	@echo '  uboot-menuconfig       - Run U-Boot menuconfig'
	@echo '  uboot-savedefconfig    - Run U-Boot savedefconfig'
	@echo '  uboot-update-defconfig - Save the U-Boot configuration to the path specified'
	@echo '                             by BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE'
endef

define UBOOT_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) \
		$(MAKE) -C $(@D) $(UBOOT_MAKE_OPTS) \
		$(UBOOT_MAKE_TARGET)
endef


define UBOOT_INSTALL_IMAGES_CMDS
	$(foreach f,$(UBOOT_BINS), \
			cp -dpf $(@D)/$(f) $(BINARIES_DIR)/
	)
endef


ifeq ($(BR2_TARGET_UBOOT)$(BR_BUILDING),yy)

#
# Check U-Boot board name (for legacy) or the defconfig/custom config
# file options (for kconfig)
#
ifeq ($(BR2_TARGET_UBOOT_BUILD_SYSTEM_KCONFIG),y)
ifeq ($(BR2_TARGET_UBOOT_USE_DEFCONFIG),y)
ifeq ($(call qstrip,$(BR2_TARGET_UBOOT_BOARD_DEFCONFIG)),)
$(error No board defconfig name specified, check your BR2_TARGET_UBOOT_BOARD_DEFCONFIG setting)
endif # qstrip BR2_TARGET_UBOOT_BOARD_DEFCONFIG
endif # BR2_TARGET_UBOOT_USE_DEFCONFIG
endif # BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG
endif # BR2_TARGET_UBOOT_BUILD_SYSTEM_LEGACY




endif # BR2_TARGET_UBOOT && BR_BUILDING

$(eval $(kconfig-package))
