Q: Q.h Q.c
	gcc -c Q.h Q.c

Q_Test: Q Q.h Q_Test.c
	gcc -o test Q.o Q_Test.c
	./test

Tpool: Thread_Pool.c Thread_Pool.h Q
	gcc -c Thread_Pool.c

Tpool_test: Tpool Thread_Pool_Test.c
	gcc -o test Thread_Pool.o Thread_Pool_Test.c -pthread Q.o
	./test

clean:
	find . -name "*.o" -type f -delete
	find . -name "test" -type f -delete
	rm -rf *.gch