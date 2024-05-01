#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
ROOTFS=${OUTDIR}/rootfs
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

${CROSS_COMPILE}gcc --version

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
    
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    # Need a patch to fix multiple definition of yyloc in gcc 10.xx version
    # Patch is here : https://github.com/torvalds/linux/commit/e33a814e772cdc36436c8c188d8c42d019fda639.patch
    # Content copied in ${FINDER_APP_DIR}/kernel-yyloc-fix.patch
    echo "Applying patch"
    git apply ${FINDER_APP_DIR}/kernel-yyloc-fix.patch

fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}  defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/$ARCH/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories
ROOTFS=${OUTDIR}/rootfs
mkdir ${ROOTFS}
cd "${ROOTFS}"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp us var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # DONE:  Configure busybox
    make distclean
    make defconfig
    
else
    cd busybox
fi

# DONE: Make and install busybox
echo "Make and install busybox..."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${ROOTFS}" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
cd "${ROOTFS}"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# DONE: Add library dependencies to rootfs
export SYSROOTPATH=$(${CROSS_COMPILE}gcc -print-sysroot)
cd "${ROOTFS}"

# Copying interpreter form toolchain to rootsys
INTERPRETER_DEP=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter" |  cut -d":" -f2 | cut -d"]" -f1 | tr -d "[:space:]")
cp -a ${SYSROOTPATH}/${INTERPRETER_DEP} ${ROOTFS}/lib

# Copying required libs from toolchain to rootsys
LIBRARY_DEPS="$(${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library" |  cut -d"[" -f2 | cut -d"]" -f1)"
for dep in $LIBRARY_DEPS; do
    cp ${SYSROOTPATH}/lib64/${dep} ${ROOTFS}/lib64
done

# DONE: Make device nodes : (1) null device, (2) console device
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1
ls -l dev

# DONE: Clean and build the writer utility
cd ${FINDER_APP_DIR}
pwd
make clean
make CROSS_COMPILE=${CROSS_COMPILE} writer

# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd ${FINDER_APP_DIR}
cp {finder.sh,conf/username.txt,conf/assignment.txt,finder-test.sh,autorun-qemu.sh} ${ROOTFS}/home

# DONE: Chown the root directory
echo "Changing root fs permissions..."
cd "${ROOTFS}"
sudo chown -R root:root *

# DONE: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip -f initramfs.cpio
