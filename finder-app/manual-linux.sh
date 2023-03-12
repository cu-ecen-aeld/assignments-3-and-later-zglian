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
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    
    echo "clean kernel build tree"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    echo "Default config simulation in QEMU"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    echo "Build a kernel image"
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    echo "Build  modules"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    echo "Build the devicetree"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}"/linux-stable/arch/${ARCH}/boot/Image "${OUTDIR}"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p home/conf
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

echo "base directories created"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    echo "Configure busybox"
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
echo "installing busybox"
make -j4 CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
cd "${OUTDIR}"/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

echo "Add library dependencies to rootfs"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp "${SYSROOT}"/lib/ld-linux-aarch64.* "${OUTDIR}/rootfs/lib"
cp "${SYSROOT}"/lib64/libm.so.* "${OUTDIR}/rootfs/lib64"
cp "${SYSROOT}"/lib64/libresolv.so.* "${OUTDIR}/rootfs/lib64"
cp "${SYSROOT}"/lib64/libc.so.* "${OUTDIR}/rootfs/lib64"

# TODO: Make device nodes
echo "Make device nodes"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 620 dev/console c 5 1

# TODO: Clean and build the writer utility
echo "clean and build the writer utility"
cd "${FINDER_APP_DIR}"/
make clean
make arch=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

echo "Copy the finder related scripts and executables to the /home directory on the target rootfs"
cp writer "${OUTDIR}"/rootfs/home/
cp finder-test.sh "${OUTDIR}"/rootfs/home/
cp finder.sh "${OUTDIR}"/rootfs/home/
cp conf/username.txt "${OUTDIR}"/rootfs/home/
cp conf/assignment.txt "${OUTDIR}"/rootfs/home/
cp autorun-qemu.sh "${OUTDIR}"/rootfs/home/

# TODO: Chown the root directory
echo "Chown the root directory"
sudo chown root:root -R "${OUTDIR}"/rootfs


# TODO: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
cd "${OUTDIR}"/rootfs
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}"/initramfs.cpio
gzip -f "${OUTDIR}"/initramfs.cpio
