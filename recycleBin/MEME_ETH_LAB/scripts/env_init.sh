# Define env globals

# Must be sourced, check that!
script_name=$( basename ${0#-} ) #- needed if sourced no path
this_script=$( basename ${BASH_SOURCE} )
if [[ ${script_name} = ${this_script} ]] ; then
    echo ""
    echo "Please source me!!"
    echo ""
    return
fi

if test -e .git ;
then
    export BASE_DIR=$PWD
else
    echo "Please run from top of git repo"
    return
fi

# Directory Variables
export BUILDROOT_DIR="buildroot"
export BUILDROOT_CONFIG_CLEAN_COPY="scripts/buildroot.config"
export BUILDROOT_PKG_TREE_CLEAN_COPY="scripts/Config.in"
export BUILDROOT_CONFIG_DEST="${BUILDROOT_DIR}/.config"
export BUILDROOT_PKG_TREE_DEST="${BUILDROOT_DIR}/package/Config.in"

export LINDIR="${BUILDROOT_DIR}/output/build/linux-custom"
export KERNEL_IMG="${BUILDROOT_DIR}/output/images/Image"
export ROOTFS="${BUILDROOT_DIR}/output/images/rootfs.ext4"
export KERNEL_DEBUG_IMG="${BUILDROOT_DIR}/output/build/linux-*/vmlinux"
export SD_IMAGE="${BUILDROOT_DIR}/output/images/sdcard.img"

export EXTERNAL_PACKAGES_DIR="extern_packages"

export GDB_CMD="scripts/gdb_cmds.txt"
export AARCH_GDB="./${BUILDROOT_DIR}/output/host/bin/aarch64-linux-gdb"
export LX_FLAG_GDB="set auto-load safe-path ./buildroot/output/build/linux-custom/"
export ENV_INIT="true"