BR2_EXTERNAL := $(CURDIR)


BUILDROOT_OUT=$(CURDIR)/output/build
ARM_OUTPUT=$(CURDIR)/output/arm
HOST_OUTPUT=$(CURDIR)/output/host

.PHONY: all menuconfig savedefconfig build clean \
	pkg-%

all: build

%_defconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot O=$(output) $@

menuconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot menuconfig O=$(output)
savedefconfig:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot savedefconfig O=$(output)

build:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot O=$(output)

clean:
	find $(BUILDROOT_OUT) -mindepth 1 -maxdepth 1 \
		! -path $(BUILDROOT_OUT)/images -print -exec rm -rf {} \;
	rm -rf $(BUILDROOT_OUT=)/images/*

flush-rootfs:
	find $(BUILDROOT_OUT) -name .stamp_target_installed -delete
	rm -rf $(BUILDROOT_OUT)/target/*

# 'Package-specific:'
# '  pkg-<pkg>                  - Build and install <pkg> and all its dependencies'
# '  pkg-<pkg>-source           - Only download the source files for <pkg>'
# '  pkg-<pkg>-extract          - Extract <pkg> sources'
# '  pkg-<pkg>-patch            - Apply patches to <pkg>'
# '  pkg-<pkg>-depends          - Build <pkg>'\''s dependencies'
# '  pkg-<pkg>-configure        - Build <pkg> up to the configure step'
# '  pkg-<pkg>-build            - Build <pkg> up to the build step'
# '  pkg-<pkg>-dirclean         - Remove <pkg> build directory'
# '  pkg-<pkg>-reconfigure      - Restart the build from the configure step'
# '  pkg-<pkg>-rebuild          - Restart the build from the build step'
pkg-%:
	BR2_EXTERNAL=$(BR2_EXTERNAL) \
		$(MAKE) -C buildroot $* O=$(BUILDROOT_OUT)

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
		$(MAKE) -C buildroot O=$(BUILDROOT_OUT) lingyun

help:
	@[ -x $(shell which less) ] && \
		less $(CURDIR)/scripts/make_help.txt || \
		cat $(CURDIR)/scripts/make_help.txt

.PHONY: help
