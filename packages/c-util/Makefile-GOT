my_puts: my_puts.c
	gcc -fPIC -c my_puts.c -fno-asynchronous-unwind-tables
	objcopy --remove-section=.note.gnu.property --remove-section=.note.GNU-stack --remove-section=.comment my_puts.o

my_lib: my_puts
	gcc -shared -nostdlib -o libM.so my_puts.o

my_hello: my_hello.c my_lib
	gcc -nostdlib -fno-asynchronous-unwind-tables -I . -L./ my_hello.c -lM -o test

libGOT: libGOT.c
	gcc -shared -nostdlib -fPIC -fno-asynchronous-unwind-tables -o libGOT.so libGOT.c

got: libGOT got.c
	gcc -nostdlib -fno-asynchronous-unwind-tables -I . -L./ got.c -lGOT -o got

lazy: lazy.c my_lib libGOT
	gcc -nostdlib -fno-asynchronous-unwind-tables -z lazy -I . -L./ lazy.c -lM -lGOT -o lazy

virt_to_phys: virt_to_phys.c
	gcc -o virt_to_phys virt_to_phys.c

clean:
	rm -rf *o test *.so lazy virt_to_phys