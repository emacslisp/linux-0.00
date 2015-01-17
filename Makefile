

all: Image

Image: boot kernel
	cat boot kernel > Image
	sync

boot: boot.o
	ld -Ttext 0 -Tdata 7c00 --oformat binary boot.o -o boot

boot.o: boot.s
	as boot.s -o boot.o

kernel: kernel.o
	ld -M -Ttext 0 -e startup_32 --oformat binary kernel.o -o kernel > system.map

kernel.o: kernel.s
	as kernel.s -o kernel.o

clean:
	@rm -fv boot.o kernel.o boot kernel *~
 
