FLAGS = -I ../MEME_Lib/ -nostdlib -fno-asynchronous-unwind-tables -static

proc: proc.c
	make -C ../MEME_Lib/
	gcc $(FLAGS) -o proc proc.c ../MEME_Lib/lib_meme.o

rusage: rusage.c
	make -C ../MEME_Lib/
	gcc  $(FLAGS) -o rusage rusage.c ../MEME_Lib/lib_meme.o

sbrk: sbrk_test.c
	gcc -o test sbrk_test.c

state: state.c
	make -C ../MEME_Lib/
	gcc $(FLAGS) -o state state.c ../MEME_Lib/lib_meme.o

clone: clone.c
	make -C ../MEME_Lib/
	gcc $(FLAGS) -o clone clone.c ../MEME_Lib/lib_meme.o

ns: ns.c
	make procFS -C ../Appendix/Linux\ Kernel\ Interfaces/ProcFS/
	gcc -I../Appendix/Linux\ Kernel\ Interfaces/ProcFS/ -o ns ns.c ../Appendix/Linux\ Kernel\ Interfaces/ProcFS/procFS.o

clean:
	rm -rf proc rusage test state clone ns 
	make clean -C ../MEME_Lib/
	make clean -C ../Appendix/Linux\ Kernel\ Interfaces/ProcFS/
