CFLAGS = -Wall -O2

all: timer

timer: timer.c timer.c
	gcc $(CFLAGS) -c timer.c

test: timer timer_test.c
	gcc $(CFLAGS) -o out timer.o timer_test.c

clean:
	rm -f *.o out