CFLAGS 	= -W -Wall -Wno-main -fomit-frame-pointer -nostdinc -Iinclude 
SYSOBJS = boot/head.o kernel.o system_call.o main.o

all: Image

Image: boot/boot system
	cat boot/boot system > Image
	sync

boot/boot: boot/boot.o
	ld -Ttext 0 -Tdata 7c00 --oformat binary boot/boot.o -o boot/boot

boot/boot.o: boot/boot.s
	as boot/boot.s -o boot/boot.o

system: $(SYSOBJS)
	ld -M -Ttext 0 -e startup_32 --oformat binary $(SYSOBJS) -o system > system.map

boot/head.o: boot/head.s
	as boot/head.s -o boot/head.o

main.o: main.c
	cc -c $(CFLAGS) main.c -o main.o

kernel.o: kernel.c head.h kernel.h
	cc -c $(CFLAGS) kernel.c -o kernel.o

system_call.o:system_call.s
	as system_call.s -o system_call.o

clean:
	@rm -fv $(SYSOBJS) boot/boot.o boot/boot system *~ boot/*~
 
