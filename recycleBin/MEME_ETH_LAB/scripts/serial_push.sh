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

if [ $# != 1 ]; then
    echo "error usage ./create_empty_app.sh <app>"
    exit
fi

if ! test -f $1; then
    echo "File ${1} doesnt exist.."
    exit
fi

read -p 'Have you booted and logged into device? (y/n): ' build
if [ "$build" = "y" ]; then
    minicom -S minicom_recv.txt < ./scripts/escape.txt
    sz $1 > /dev/pts/1 < /dev/pts/1
else
    echo "Please log in.."
    exit
fi