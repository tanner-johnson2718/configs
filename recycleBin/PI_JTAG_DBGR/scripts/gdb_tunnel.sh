if [ $# != 1 ]; then
    echo "error usage ./gdb_tunnel.sh <IP>"
    exit
fi

ssh -N -L 3333:$1:3333 pi@$1
