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



################################################################################
# kernel-module -- the target generator macro for kernel module packages
################################################################################

cambricon-arm-kernel-module = $(call inner-kernel-module,$(pkgname),$(call UPPERCASE,$(pkgname)))
