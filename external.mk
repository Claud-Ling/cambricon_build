#Rules for building packages
include $(BR2_EXTERNAL_cambricon_buildroot_PATH)/package/pkg-cambricon-generic.mk

include $(sort $(wildcard $(BR2_EXTERNAL_cambricon_buildroot_PATH)/package/*/cambricon_build.mk))


lingyun:
	@$(call MESSAGE,"####LINGYUN####"$(HOST_CONFIGURE_OPTS))
	
	
