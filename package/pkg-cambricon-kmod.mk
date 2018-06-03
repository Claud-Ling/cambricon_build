################################################################################
# kernel module infrastructure for building Linux kernel modules
#
# This file implements an infrastructure that eases development of package
# .mk files for out-of-tree Linux kernel modules. It should be used for all
# packages that build a Linux kernel module using the kernel's out-of-tree
# buildsystem, unless they use a complex custom buildsystem.
#
# The kernel-module infrastructure requires the packages that use it to also
# use another package infrastructure. kernel-module only defines post-build
# and post-install hooks. This allows the package to build both kernel
# modules and/or user-space components (with any of the other *-package
# infra).
#
# As such, it is to be used in conjunction with another *-package infra,
# like so:
#
#   $(eval $(cambricon-arm-kernel-module))
#   $(eval $(cambricon-arm-generic-package))
################################################################################

HOST_LINUX_DIR = /lib/modules/$(shell uname -r)/build

HOST_LINUX_MAKE_FLAGS = \
	HOSTCC="$(HOSTCC) $(HOST_CFLAGS) $(HOST_LDFLAGS)" \
	INSTALL_MOD_PATH=$(HOST_OUTPUT) \
	DEPMOD=$(HOST_DIR)/sbin/depmod


################################################################################
# argument 1 is the lowercase package name
# argument 2 is the uppercase package name
################################################################################
define cambricon-host-inner-kernel-module

# This is only defined in some infrastructures (e.g. autotools, cmake),
# but not in others (e.g. generic). So define it here as well.
$(2)_MAKE ?= $$(MAKE)

# If not specified, consider the source of the kernel module to be at
# the root of the package.
$(2)_MODULE_SUBDIRS ?= .

#
# Process _BUILD_MAKE_OPT
#
ifdef HOST_MODULE_MAKE_OPTS
  $(2)_MODULE_MAKE_OPTS += $(HOST_MODULE_MAKE_OPTS)
endif

ifdef HOST_MODULE_SUBDIRS
  $(2)_MODULE_SUBDIRS += $(HOST_MODULE_SUBDIRS)
endif

# Build the kernel module(s)
# Force PWD for those packages that want to use it to find their
# includes and other support files (Booo!)
define $(2)_KERNEL_MODULES_BUILD
	@$$(call MESSAGE,"Building kernel module(s)")
	$$(foreach d,$$($(2)_MODULE_SUBDIRS), \
		$$(LINUX_MAKE_ENV) $$($$(PKG)_MAKE) \
			-C $$(HOST_LINUX_DIR) \
			$$(HOST_LINUX_MAKE_FLAGS) \
			$$($(2)_MODULE_MAKE_OPTS) \
			PWD=$$(@D)/$$(d) \
			M=$$(@D)/$$(d) \
			modules$$(sep))
endef
$(2)_POST_BUILD_HOOKS += $(2)_KERNEL_MODULES_BUILD

# Install the kernel module(s)
# Force PWD for those packages that want to use it to find their
# includes and other support files (Booo!)
define $(2)_KERNEL_MODULES_INSTALL
	@$$(call MESSAGE,"Installing kernel module(s)")
	$$(foreach d,$$($(2)_MODULE_SUBDIRS), \
		$$(LINUX_MAKE_ENV) $$($$(PKG)_MAKE) \
			-C $$(HOST_LINUX_DIR) \
			$$(HOST_LINUX_MAKE_FLAGS) \
			$$($(2)_MODULE_MAKE_OPTS) \
			PWD=$$(@D)/$$(d) \
			M=$$(@D)/$$(d) \
			modules_install$$(sep))
endef
$(2)_POST_INSTALL_HOOKS += $(2)_KERNEL_MODULES_INSTALL

# undefine the reference
HOST_MODULE_MAKE_OPTS =
HOST_MODULE_SUBDIRS =

endef

################################################################################
# argument 1 is the lowercase package name
# argument 2 is the uppercase package name
################################################################################
define cambricon-arm-inner-kernel-module

#
# Process _BUILD_MAKE_OPT
#
ifdef ARM_MODULE_MAKE_OPTS
  $(2)_MODULE_MAKE_OPTS += $(ARM_MODULE_MAKE_OPTS)
endif

ifdef ARM_MODULE_SUBDIRS
  $(2)_MODULE_SUBDIRS += $(ARM_MODULE_SUBDIRS)
endif

$(call inner-kernel-module,$(1),$(2))

# undefine the reference
ARM_MODULE_MAKE_OPTS =
ARM_MODULE_SUBDIRS =

endef

################################################################################
# kernel-module -- the target generator macro for kernel module packages
################################################################################

cambricon-arm-kernel-module = $(call cambricon-arm-inner-kernel-module,$(pkgname),$(call UPPERCASE,$(pkgname)))

cambricon-host-kernel-module = $(call cambricon-host-inner-kernel-module,host-$(pkgname),$(call UPPERCASE,host-$(pkgname)))
