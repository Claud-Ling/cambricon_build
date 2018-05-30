
################################################################################
# FOO
################################################################################

ARM_MAKE_OPTS += \
	__BUILDING_ARM_FOO__=1	\
	__HELP_FOO__=1

$(eval $(cambricon-arm-generic-package))

X86_MAKE_OPTS = \
	__BUILDING_X86_FOO__=1	\
	__HELP_FOO__=1
#$(eval $(cambricon-x86-generic-package))
