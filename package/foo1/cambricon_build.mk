
################################################################################
# foo
################################################################################
ARM_BUILD_DEPENDENCIES = foo

ARM_BUILD_MAKE_OPTS += \
	__BUILDING_ARM_FOO1__=1	\
	__HELP_FOO1__=1

ARM_BUILD_INSTALL_EXECS = foo
ARM_BUILD_INSTALL_LIBRARIES = libfoo1/libfoo1.so libfoo1/libfoo1.a
ARM_BUILD_INSTALL_HEADERS = inc/foo1.h inc/foo1-a.h
ARM_BUILD_INSTALL_KMOD =

$(eval $(cambricon-arm-generic-package))

################################################################################
# host-foo1
################################################################################
HOST_BUILD_DEPENDEDCIES = host-foo
HOST_BUILD_MAKE_OPTS = \
	__BUILDING_X86_FOO1__=1	\
	__HELP_FOO1__=1

HOST_BUILD_INSTALL_TARGETS = foo 
HOST_BUILD_INSTALL_LIBRARIES = libfoo1.so libfoo1.a
HOST_BUILD_INSTALL_HEADERS = foo1.h
HOST_BUILD_INSTALL_KMOD =

$(eval $(cambricon-host-generic-package))

