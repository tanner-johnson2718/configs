if [ $# != 1 ]; then
    echo "error plz pass 1 arg that is nic if name"
    exit
fi

if ! test -d /sys/class/net/$1/statistics; then
    echo "error invalid nic name"
    exit
fi

PWD=$(pwd)
cd /sys/class/net/$1/statistics/

for d in * ; do

    if ! test -f $d; then
        continue
    fi

    v=$(cat $d)
    printf "%-25s %s\n" "$d" "$v" 

done

cd $PWD