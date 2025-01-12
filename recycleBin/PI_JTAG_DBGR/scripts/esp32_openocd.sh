if [ $# != 2 ]; then
    echo "error usage ./esp32_connect.sh <rate (khz)> <IP>"
    exit
fi

openocd -f ./openocd_config/rpi4_interface.cfg -f target/esp32.cfg -c "adapter speed ${1}" -c "bindto ${2}"  -c "init; halt; esp appimage_offset 0x20000"