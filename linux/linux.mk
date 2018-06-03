################################################################################
#
# Linux kernel target
#
################################################################################

LINUX_VERSION = 
LINUX_LICENSE = GPL-2.0
LINUX_LICENSE_FILES = COPYING

define LINUX_HELP_CMDS
	@echo '  linux-menuconfig       - Run Linux kernel menuconfig'
	@echo '  linux-savedefconfig    - Run Linux kernel savedefconfig'
	@echo '  linux-update-defconfig - Save the Linux configuration to the path specified'
	@echo '                             by BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE'
endef

LINUX_SITE = "${SOURCE_CODE_PATH}/linux"
LINUX_SITE_METHOD = local

LINUX_INSTALL_IMAGES = YES
#LINUX_DEPENDENCIES += host-bison host-flex host-kmod


LINUX_MAKE_FLAGS = \
	HOSTCC="$(HOSTCC) $(HOST_CFLAGS) $(HOST_LDFLAGS)" \
	ARCH=$(KERNEL_ARCH) \
	INSTALL_MOD_PATH=$(TARGET_DIR) \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	DEPMOD=$(HOST_DIR)/sbin/depmod

LINUX_MAKE_ENV = \
	$(TARGET_MAKE_ENV) \
	BR_BINARIES_DIR=$(BINARIES_DIR)

# Get the real Linux version, which tells us where kernel modules are
# going to be installed in the target filesystem.
LINUX_VERSION_PROBED = `$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) --no-print-directory -s kernelrelease 2>/dev/null`

LINUX_DTS_NAME += $(call qstrip,$(BR2_LINUX_KERNEL_INTREE_DTS_NAME))

LINUX_DTBS = $(addsuffix .dtb,$(addprefix cambricon/,$(LINUX_DTS_NAME)))

ifeq ($(BR2_LINUX_KERNEL_IMAGE_TARGET_CUSTOM),y)
LINUX_IMAGE_NAME = $(call qstrip,$(BR2_LINUX_KERNEL_IMAGE_NAME))
LINUX_TARGET_NAME = $(call qstrip,$(BR2_LINUX_KERNEL_IMAGE_TARGET_NAME))
ifeq ($(LINUX_IMAGE_NAME),)
LINUX_IMAGE_NAME = $(LINUX_TARGET_NAME)
endif
else
ifeq ($(BR2_LINUX_KERNEL_UIMAGE),y)
LINUX_IMAGE_NAME = uImage
else ifeq ($(BR2_LINUX_KERNEL_APPENDED_UIMAGE),y)
LINUX_IMAGE_NAME = uImage
else ifeq ($(BR2_LINUX_KERNEL_BZIMAGE),y)
LINUX_IMAGE_NAME = bzImage
else ifeq ($(BR2_LINUX_KERNEL_ZIMAGE),y)
LINUX_IMAGE_NAME = zImage
else ifeq ($(BR2_LINUX_KERNEL_ZIMAGE_EPAPR),y)
LINUX_IMAGE_NAME = zImage.epapr
else ifeq ($(BR2_LINUX_KERNEL_APPENDED_ZIMAGE),y)
LINUX_IMAGE_NAME = zImage
else ifeq ($(BR2_LINUX_KERNEL_CUIMAGE),y)
LINUX_IMAGE_NAME = cuImage.$(LINUX_DTS_NAME)
else ifeq ($(BR2_LINUX_KERNEL_SIMPLEIMAGE),y)
LINUX_IMAGE_NAME = simpleImage.$(LINUX_DTS_NAME)
else ifeq ($(BR2_LINUX_KERNEL_IMAGE),y)
LINUX_IMAGE_NAME = Image
else ifeq ($(BR2_LINUX_KERNEL_LINUX_BIN),y)
LINUX_IMAGE_NAME = linux.bin
else ifeq ($(BR2_LINUX_KERNEL_VMLINUX_BIN),y)
LINUX_IMAGE_NAME = vmlinux.bin
else ifeq ($(BR2_LINUX_KERNEL_VMLINUX),y)
LINUX_IMAGE_NAME = vmlinux
else ifeq ($(BR2_LINUX_KERNEL_VMLINUZ),y)
LINUX_IMAGE_NAME = vmlinuz
else ifeq ($(BR2_LINUX_KERNEL_VMLINUZ_BIN),y)
LINUX_IMAGE_NAME = vmlinuz.bin
endif
# The if-else blocks above are all the image types we know of, and all
# come from a Kconfig choice, so we know we have LINUX_IMAGE_NAME set
# to something
LINUX_TARGET_NAME = $(LINUX_IMAGE_NAME)
endif


# Compute the arch path, since i386 and x86_64 are in arch/x86 and not
# in arch/$(KERNEL_ARCH). Even if the kernel creates symbolic links
# for bzImage, arch/i386 and arch/x86_64 do not exist when copying the
# defconfig file.
ifeq ($(KERNEL_ARCH),i386)
LINUX_ARCH_PATH = $(LINUX_DIR)/arch/x86
else ifeq ($(KERNEL_ARCH),x86_64)
LINUX_ARCH_PATH = $(LINUX_DIR)/arch/x86
else
LINUX_ARCH_PATH = $(LINUX_DIR)/arch/$(KERNEL_ARCH)
endif

ifeq ($(BR2_LINUX_KERNEL_VMLINUX),y)
LINUX_IMAGE_PATH = $(LINUX_DIR)/$(LINUX_IMAGE_NAME)
else ifeq ($(BR2_LINUX_KERNEL_VMLINUZ),y)
LINUX_IMAGE_PATH = $(LINUX_DIR)/$(LINUX_IMAGE_NAME)
else ifeq ($(BR2_LINUX_KERNEL_VMLINUZ_BIN),y)
LINUX_IMAGE_PATH = $(LINUX_DIR)/$(LINUX_IMAGE_NAME)
else
LINUX_IMAGE_PATH = $(LINUX_ARCH_PATH)/boot/$(LINUX_IMAGE_NAME)
endif # BR2_LINUX_KERNEL_VMLINUX


ifeq ($(BR2_LINUX_KERNEL_USE_DEFCONFIG),y)
LINUX_KCONFIG_DEFCONFIG = $(call qstrip,$(BR2_LINUX_KERNEL_DEFCONFIG))_defconfig
else ifeq ($(BR2_LINUX_KERNEL_USE_ARCH_DEFAULT_CONFIG),y)
LINUX_KCONFIG_DEFCONFIG = defconfig
else ifeq ($(BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG),y)
LINUX_KCONFIG_FILE = $(call qstrip,$(BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE))
endif
LINUX_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig
LINUX_KCONFIG_OPTS = $(LINUX_MAKE_FLAGS)


ifeq ($(BR2_LINUX_KERNEL_DTS_SUPPORT),y)
define LINUX_BUILD_DTB
	$(LINUX_MAKE_ENV) $(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) $(LINUX_DTBS)
endef
define LINUX_INSTALL_DTB
	# dtbs moved from arch/<ARCH>/boot to arch/<ARCH>/boot/dts since 3.8-rc1
	cp $(addprefix \
		$(LINUX_ARCH_PATH)/boot/$(if $(wildcard \
		$(addprefix $(LINUX_ARCH_PATH)/boot/dts/,$(LINUX_DTBS))),dts/),$(LINUX_DTBS)) \
		$(1)
endef
endif # BR2_LINUX_KERNEL_DTS_SUPPORT


# Compilation. We make sure the kernel gets rebuilt when the
# configuration has changed.
define LINUX_BUILD_CMDS
	$(LINUX_MAKE_ENV) $(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) $(LINUX_TARGET_NAME) -j$(PARALLEL_JOBS)
	$(LINUX_MAKE_ENV) $(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) modules -j$(PARALLEL_JOBS)
	$(LINUX_BUILD_DTB)
endef

define LINUX_INSTALL_IMAGE
	$(INSTALL) -m 0644 -D $(LINUX_IMAGE_PATH) $(1)/$(LINUX_IMAGE_NAME)
endef


define LINUX_INSTALL_HOST_TOOLS
	# Installing dtc (device tree compiler) as host tool, if selected
	if grep -q "CONFIG_DTC=y" $(@D)/.config; then \
		$(INSTALL) -D -m 0755 $(@D)/scripts/dtc/dtc $(HOST_DIR)/bin/linux-dtc ; \
		if [ ! -e $(HOST_DIR)/bin/dtc ]; then \
			ln -sf linux-dtc $(HOST_DIR)/bin/dtc ; \
		fi \
	fi
endef

define LINUX_INSTALL_IMAGES_CMDS
	$(call LINUX_INSTALL_IMAGE,$(BINARIES_DIR))
	$(call LINUX_INSTALL_DTB,$(BINARIES_DIR))
endef

define LINUX_INSTALL_TARGET_CMDS
	# Install modules and remove symbolic links pointing to build
	# directories, not relevant on the target
	@if grep -q "CONFIG_MODULES=y" $(@D)/.config; then \
		$(LINUX_MAKE_ENV) $(MAKE1) $(LINUX_MAKE_FLAGS) -C $(@D) modules_install; \
		rm -f $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/build ; \
		rm -f $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/source ; \
	fi
	$(LINUX_INSTALL_HOST_TOOLS)
endef


ifeq ($(BR_BUILDING),y)

ifeq ($(BR2_LINUX_KERNEL_USE_DEFCONFIG),y)
# We must use the user-supplied kconfig value, because
# LINUX_KCONFIG_DEFCONFIG will at least contain the
# trailing _defconfig
ifeq ($(call qstrip,$(BR2_LINUX_KERNEL_DEFCONFIG)),)
$(error No kernel defconfig name specified, check your BR2_LINUX_KERNEL_DEFCONFIG setting)
endif
endif

ifeq ($(BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG),y)
ifeq ($(LINUX_KCONFIG_FILE),)
$(error No kernel configuration file specified, check your BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE setting)
endif
endif

ifeq ($(BR2_LINUX_KERNEL_DTS_SUPPORT):$(strip $(LINUX_DTS_NAME)),y:)
$(error No kernel device tree source specified, check your \
	BR2_LINUX_KERNEL_INTREE_DTS_NAME / BR2_LINUX_KERNEL_CUSTOM_DTS_PATH settings)
endif

endif # BR_BUILDING

$(eval $(kconfig-package))

