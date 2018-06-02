#!/usr/bin/env bash


main()
{
	local resources_path=${BINARIES_DIR}/c20_res

	pushd ${BINARIES_DIR}

	if [ -f bl1.bin ]; then
		install -D -m 0644 bl1.bin ${resources_path}/bootloader/bl1.bin
	fi

	if [ -f fip.bin ]; then
		install -D -m 0644 fip.bin ${resources_path}/bootloader/fip.bin
	fi
	
	if [ -f Image ]; then
		install -D -m 0644 Image ${resources_path}/kernel/Image
	fi

	if [ -f cambr-c20.dtb ]; then
		install -D -m 0644 cambr-c20.dtb ${resources_path}/kernel/cambr-c20.dtb
	fi

	if [ -f rootfs.tar ]; then
		mkdir -p ${resources_path}/rootfs/rootfs
		tar xf rootfs.tar -C ${resources_path}/rootfs/rootfs
	fi

	popd
}

main $@
