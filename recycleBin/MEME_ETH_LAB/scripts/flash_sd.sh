# Pass the name of the block device to flash. Unmount all mounted partitions. Use dd command to flash the device

# Check that env_init is sourced
if [ -z "$ENV_INIT" ]
then
    echo ""
    echo "Please source env_init.sh"
    echo ""
    exit
fi

# Check 1 input arg
if [ $# != 1 ]; then
    echo "error usage ./flash_sd.sh <dev>"
    exit
fi

# Check base dir
if [ $PWD != $BASE_DIR ] ;
then
    echo "Please run from ${BASE_DIR}"
    exit
fi

# Check that block device actuall exists
if ! test -b /dev/$1; then
    echo "Could not find device /dev/${1}"
    exit
fi

proc_out=$(cat /proc/mounts | grep ${1} | awk '{print $2}' )
mounts=($proc_out)

for i in $proc_out
do
    :
    echo "Found mount ${i}"
    read -p 'Unmount? (y/n): ' build
    if [ "$build" = "y" ]; then
        sudo umount $i
    fi
done

read -p 'Flash /dev/$1 (y/n): ' build
if [ "$build" = "y" ]; then
    sudo dd if=$SD_IMAGE of=/dev/$1 bs=4M status=progress
fi