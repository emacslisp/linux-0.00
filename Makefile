

all: boot

boot: boot.o
	ld -Ttext 0 -Tdata 7c00 --oformat binary boot.o -o boot

boot.o: boot.s
	as boot.s -o boot.o

clean:
	@rm -fv boot.o *~
 
