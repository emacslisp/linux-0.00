 /* head.s 

   A 32 bit code, running in 386 protected mode. It will setup a new GDT, 
   update segment registres and print 'A' on the screen.

   copyright(C) 2015 Issam Abdallah, Tunisia.
   E-mail: iabdallah@yandex.com

   License: GPL

*/

	.global	startup_32
	.text

startup_32:

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	stack_ptr, %esp		# load SS and ESP

	lgdt	gdt_ptr

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	stack_ptr, %esp

	mov	$0x18, %ax		# GDT[3] - video memory descriptor
	mov	%ax, %gs	 
	movb	$'A, %al
	movb	%al, %gs:0		# print 'A'
	movb	$0x2f, %al		# green - white
	movb	%al, %gs:1

hang: 
	jmp	hang

######################################### * GDT: granularity = 1 => segment size = limit * 4Kb

gdt:	.quad	0x0000000000000000	# NULL descriptor!
	.quad	0x00c09a00000007ff	# 8Mb code segment (CS=0x08), base = 0x0000
	.quad	0x00c09200000007ff	# 8Mb data segment (DS=SS=0x10), base = 0x0000
	.quad	0x00c0920b80000001	# 4Kb video memory (Sel=0x18): base = 0xb8000 - 25*80 text mode 

gdt_ptr:
	.word	. - gdt -1		# Limit: GDT size
	.long	gdt			# Base: pointer to the first GDT entry (the NULL descr) 
	
######################################### * stack

	.balign	4
	.fill 128, 4, 0			# reserve 32 words for the stack
stack_ptr:				# ESP initially points to the bottom of the stack - the stack grows up toward low adresses!
	.long .				# ESP
	.word 0x10			# SS: the register that points to the segment conaining the stack!

#########################################

	.fill 128, 4, 0

