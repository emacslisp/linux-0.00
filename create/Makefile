
boot/boot: boot/boot.o
	ld -Ttext 0 -Tdata 7c00 --oformat binary boot/boot.o -o boot/boot

boot/boot.o: boot/boot.s
	as boot/boot.s -o boot/boot.o
