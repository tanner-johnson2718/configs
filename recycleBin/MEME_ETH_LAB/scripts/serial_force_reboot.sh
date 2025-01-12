# Check that env_init is sourced
if [ -z "$ENV_INIT" ]
then
    echo ""
    echo "Please source env_init.sh"
    echo ""
    exit
fi

# Check base dir
if [ $PWD != $BASE_DIR ] ;
then
    echo "Please run from ${BASE_DIR}"
    exit
fi

minicom -S ./scripts/minicom_reboot.txt < ./scripts/escape.txt