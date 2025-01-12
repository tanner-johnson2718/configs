if [ $# != 1 ]; then
    echo "error usage ./bcm2711_connect.sh <IP>"
    exit
fi

openocd -f ./openocd_config/rpi4_interface.cfg -f ./openocd_config/bcm2711_target.cfg -c "bindto ${1}" 
