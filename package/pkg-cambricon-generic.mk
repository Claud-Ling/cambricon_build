################################################################################
# Cambricon Generic package infrastructure
#
# This file implements an infrastructure that eases development of
# package .mk files. It should be used for packages that do not rely
# on a well-known build system for which Buildroot has a dedicated
# infrastructure (so far, Buildroot has special support for
# autotools-based and CMake-based packages).
#
################################################################################

################################################################################
#  argument 1 is the lowercase package name
#  argument 2 is the uppercase package name, including a HOST_ prefix
#             for host packages
#  argument 3 is the uppercase package name, without the HOST_ prefix
#             for host packages
#  argument 4 is the type (target or host)
################################################################################
define inner-cambricon-generic-package

BR2_PACKAGE_$(2) = y

ifndef $(2)_MAKE
 ifdef $(3)_MAKE
  $(2)_MAKE = $$($(3)_MAKE)
 else
  $(2)_MAKE ?= $$(MAKE)
 endif
endif

$(3)_VERSION		?= 1.0.4
$(2)_SITE		= "${BR2_EXTERNAL_cambricon_buildroot_PATH}/package/$(1)"
$(2)_SITE_METHOD	= local

#
# Process _DEPENDENCIES
#
ifeq ($(4),target)
  ifdef ARM_BUILD_DEPENDENCIES
    $(2)_DEPENDENCIES += $(ARM_BUILD_DEPENDENCIES)
  endif
else
  ifdef HOST_BUILD_DEPENDENCIES
    $(2)_DEPENDENCIES += $(HOST_BUILD_DEPENDENCIES)
  endif
endif

#
# Process _BUILD_MAKE_OPT
#
ifeq ($(4),target)
  ifdef ARM_BUILD_MAKE_OPTS
    $(2)_MAKE_OPTS += $(ARM_BUILD_MAKE_OPTS)
  endif
else
  ifdef HOST_BUILD_MAKE_OPTS
    $(2)_MAKE_OPTS += $(HOST_BUILD_MAKE_OPTS)
  endif
endif

#
# Build step. Only define it if not already defined by the package .mk
# file.
#
ifndef $(2)_BUILD_CMDS
 ifeq ($(4),target)
  define $(2)_BUILD_CMDS
	$$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $$($$(PKG)_MAKE_ENV) $$($$(PKG)_MAKE) $$($$(PKG)_MAKE_OPTS) -C $$($$(PKG)_SRCDIR)
  endef
 else
  define $(2)_BUILD_CMDS
	$$(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) $$($$(PKG)_MAKE_ENV) $$($$(PKG)_MAKE) $$($$(PKG)_MAKE_OPTS) -C $$($$(PKG)_SRCDIR)
  endef
 endif
endif


#
# Target installation step. Only define it if not already defined by
# the package .mk file.
#
ifndef $(2)_INSTALL_TARGET_CMDS
define $(2)_INSTALL_TARGET_CMDS
	$(foreach exec,$(ARM_BUILD_INSTALL_EXECS),\
		@$$(INSTALL) -d $(TARGET_DIR)/usr/local;
		$$(INSTALL) -m 0755 $$($$(PKG)_SRCDIR)$(exec) $(TARGET_DIR)/usr/local/$(sep))

	$(foreach lib,$(ARM_BUILD_INSTALL_LIBRARIES),\
		$$(INSTALL) -m 0755 $$($$(PKG)_SRCDIR)$(lib) $(TARGET_DIR)/lib/$(sep))


	$(foreach header,$(ARM_BUILD_INSTALL_HEADERS),\
		@$$(INSTALL) -d $(STAGING_DIR)/usr/include/cambricon;
		$$(INSTALL) -m 0644 $$($$(PKG)_SRCDIR)$(header) $(STAGING_DIR)/usr/include/cambricon$(sep))

	$(foreach lib,$(ARM_BUILD_INSTALL_LIBRARIES),\
		$$(INSTALL) -m 0755 $$($$(PKG)_SRCDIR)$(lib) $(STAGING_DIR)/usr/lib/$(sep))
endef
endif

#
# Host installation step. Only define it if not already defined by the
# package .mk file.
#
ifndef $(2)_INSTALL_CMDS
define $(2)_INSTALL_CMDS
	$(foreach exec,$(HOST_BUILD_INSTALL_EXECS),\
		$$(INSTALL) -D $$($$(PKG)_SRCDIR)$(exec) $(HOST_DIR)/usr/local/$(exec)$(sep))

	$(foreach lib,$(HOST_BUILD_INSTALL_LIBRARIES),\
		$$(INSTALL) -D $$($$(PKG)_SRCDIR)$(lib) $(HOST_DIR)/lib/$(lib)$(sep))

	$(foreach header,$(HOST_BUILD_INSTALL_HEADERS),\
		$$(INSTALL) -D $$($$(PKG)_SRCDIR)$(header) $(HOST_DIR)/include/$(header)$(sep))

endef
endif

# Call the generic package infrastructure to generate the necessary
# make targets
$(call inner-generic-package,$(1),$(2),$(3),$(4))

endef

cambricon-arm-generic-package = $(call inner-cambricon-generic-package,$(pkgname),$(call UPPERCASE,$(pkgname)),$(call UPPERCASE,$(pkgname)),target)
cambricon-host-generic-package = $(call inner-cambricon-generic-package,host-$(pkgname),$(call UPPERCASE,host-$(pkgname)),$(call UPPERCASE,$(pkgname)),host)

