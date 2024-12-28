flags = -static -nostdlib -fPIC -fno-asynchronous-unwind-tables

lib_meme: lib_meme.c lib_meme.h
	gcc $(flags) -c lib_meme.c

test: lib_meme
	gcc $(flags) -o test test.c lib_meme.o

clean:
	rm -rf *.o test