# Force a rebuild of an out of tree app and delete and rebuild the rootfs and SD card image

# Check that env_init is sourced
if [ -z "$ENV_INIT" ]
then
    echo ""
    echo "Please source env_init.sh"
    echo ""
    exit
fi

# Check usage
if [ $# != 1 ]; then
    echo "error usage ./rebuild_app <app>"
    exit
fi

# Check that we are at the base dir
if [ $PWD != $BASE_DIR ] ;
then
    echo "Please run from ${BASE_DIR}"
    exit
fi

# CHeck that the external user space app exists extrernally
if ! test -f ${EXTERNAL_PACKAGES_DIR}/$1/Config.in; then
    echo "Failed to find ${EXTERNAL_PACKAGES_DIR}/$1/Config.in .. Out of Tree App does not exist"
    exit
fi
if ! test -f ${EXTERNAL_PACKAGES_DIR}/$1/$1.mk; then
    echo "Failed to find ${EXTERNAL_PACKAGES_DIR}/$1/$1.mk .. Out of Tree App does not exist"
    exit
fi
 
# Check that the external user space app is registered with BR
if ! test -f ${BUILDROOT_DIR}/package/$1/Config.in; then
    echo "Failed to find ${BUILDROOT_DIR}/package/$1/Config.in .. use build.sh for new app"
    exit
fi
if ! test -f  ${BUILDROOT_DIR}/package/$1/$1.mk; then
    echo "Failed to find  ${BUILDROOT_DIR}/package/$1/$1.mk .. use build.sh for new app"
    exit
fi

# delete indicated apps source and rootfs
rm -r ${BUILDROOT_DIR}/output/build/$1-*
rm -r ${ROOTFS}
rm -r ${SD_IMAGE}

# delete metadata
rm -rf ${BUILDROOT_DIR}/package/$1

# copy meta data
mkdir ${BUILDROOT_DIR}/package/$1
cp ${EXTERNAL_PACKAGES_DIR}/$1/Config.in  ${BUILDROOT_DIR}/package/$1/Config.in
cp ${EXTERNAL_PACKAGES_DIR}/$1/$1.mk  ${BUILDROOT_DIR}/package/$1/$1.mk

#rebuild
cd ${BUILDROOT_DIR}
make $1
make
cd ..