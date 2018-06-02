BR2_EXTERNAL := $(CURDIR)


BUILDROOT_OUT=$(CURDIR)/output/.tmp
export ARM_OUTPUT=$(CURDIR)/output/arm
export HOST_OUTPUT=$(CURDIR)/output/host

$(BUILDROOT_OUT) $(ARM_OUTPUT) $(HOST_OUTPUT):
	@mkdir -p $@

.PHONY: all menuconfig savedefconfig build clean \
	pkg-%

all: build

%_defconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot O=$(BUILDROOT_OUT) $@

menuconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot menuconfig O=$(BUILDROOT_OUT)
savedefconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot savedefconfig O=$(BUILDROOT_OUT)

build: $(ARM_OUTPUT) $(HOST_OUTPUT)
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot O=$(BUILDROOT_OUT)

clean:
	find $(BUILDROOT_OUT) -mindepth 1 -maxdepth 1 \
		! -path $(BUILDROOT_OUT)/images -print -exec rm -rf {} \;
	rm -rf $(BUILDROOT_OUT)/images/*

flush-rootfs:
	find $(BUILDROOT_OUT) -name .stamp_target_installed -delete
	rm -rf $(BUILDROOT_OUT)/target/*

# 'Package-specific:'
# '  [host-]pkg-<pkgname>                  - Build and install <pkg> and all its dependencies'
# '  [host-]pkg-<pkgname>-build            - Build <pkg> up to the build step'
# '  [host-]pkg-<pkgname>-rebuild          - Restart the build from the build step'
pkg-%: $(ARM_OUTPUT) $(HOST_OUTPUT)
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot $* O=$(BUILDROOT_OUT)

host-pkg-%: $(ARM_OUTPUT) $(HOST_OUTPUT)
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot host-$* O=$(BUILDROOT_OUT)


rebuild-changed: export BUILD_TEMP=/tmp SINCE=$(SINCE)
rebuild-changed: _rebuild_changed

_rebuild_changed:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot \
			$(shell BUILD_TEMP=$(BUILD_TEMP) SINCE=$(SINCE) scripts/changed_project_targets.py) \
			O=$(BUILDROOT_OUT)

_print_db:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot all O=$(BUILDROOT_OUT) -np

show-targets:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot O=$(BUILDROOT_OUT) graph-build

help:
	@[ -x $(shell which less) ] && \
		less $(CURDIR)/scripts/make_help.txt || \
		cat $(CURDIR)/scripts/make_help.txt

.PHONY: help
