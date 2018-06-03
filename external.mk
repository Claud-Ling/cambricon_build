SOURCE_CODE_PATH=$(BR2_EXTERNAL_cambricon_buildroot_PATH)/../src

#Rules for building packages

include $(BR2_EXTERNAL_cambricon_buildroot_PATH)/package/common.mk

include $(BR2_EXTERNAL_cambricon_buildroot_PATH)/boot/common.mk

include $(BR2_EXTERNAL_cambricon_buildroot_PATH)/linux/linux.mk

include $(sort $(wildcard $(SOURCE_CODE_PATH)/*/cambricon_build.mk))


lingyun:
	@$(call MESSAGE,"####LINGYUN####"$(LINUX_DIR))
	
	
