#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
    #Patch to apply for issue with gcc10.x
    echo "Apply patch for yylloc"
    sed -i 's/YYLTYPE yylloc;//g' ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.l

    # Alternative using git apply ( the patch is at ${FINDER_APP_DIR}/kernel-yylloc-fix.patch)
    # Patch is here : https://github.com/torvalds/linux/commit/e33a814e772cdc36436c8c188d8c42d019fda639.patch
    # Content copied in ${FINDER_APP_DIR}/kernel-yyloc-fix.patch
    # git apply ${FINDER_APP_DIR}/kernel-yylloc-fix.patch
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc) defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc) all
    # make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    # make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

# TODO: Adding the Image in outdir
echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories
mkdir "$OUTDIR/rootfs"
cd "$OUTDIR/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # DONE:  Configure busybox
    # make distclean
    make defconfig
    
else
    cd busybox
fi

# DONE: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install

echo "Show Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# DONE: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp $SYSROOT/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp $SYSROOT/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp $SYSROOT/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64
cp $SYSROOT/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib

# DONE: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1

# DONE: Clean and build the writer utility 
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer ${OUTDIR}/rootfs/home

# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp finder.sh ${OUTDIR}/rootfs/home
cp -r -L conf ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# DONE: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# DONE: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
cd ${OUTDIR}/rootfs
sudo find . | sudo cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

echo "Build Successfully!"