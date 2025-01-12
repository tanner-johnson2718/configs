all: sniff.c gen.c libEth.c libEth.h
	$(CC) $(CFLAGS) -c libEth.c
	$(CC) $(CFLAGS) -o sniff sniff.c libEth.o
	$(CC) $(CFLAGS) -o gen gen.c libEth.o

clean:
	rm -rf sniff gen *.o