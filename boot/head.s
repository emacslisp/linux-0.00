/* 
 *	head.s 
 *
 *  A 32 bit code, running in 386 protected mode. It will setup IDT, GDT, 
 *  segment registres, enable interrupts and call the main function.
 *
 *  Copyright(C) 2015 Issam Abdallah, Tunisia.
 *  E-mail: iabdallah@yandex.com
 *
 *  License: GPL
 *
*/

TSS_SEL = 0x20
LDT_SEL = 0x28

	.global	startup_32, gdt, idt, task
	.text

startup_32:

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	stack_start, %esp	# load SS and ESP to point to the task's kernel stack! 

######################################### * setup GDT and IDT

	call	setup_idt
	call	setup_gdt

#########################################

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	stack_start, %esp

######################################### * Move to user mode (task)
## NOTE: IRET will cause the processor to automatically switch to another task if NT=1! 

	pushfl
	andl	$0xffffbfff, (%esp)	# ensure that NT is clear (NT = 0)! 
	popfl

	call	main			# main.c

#########################################

setup_gdt:
	lgdt	gdt_ptr
	ret

######################################### * initialize IDT

/*		Interrupt gate Descriptor (type=14 = 0xE)
  _____________________________________________________________
  |				| |   | |       | | | |       |
  |	   OFFSET 31..16	|P|DPL|0| TYPE  |0 0 0|unused | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|0|_|_|_|_|_|_|_|
  |				|			      |
  |	      SELECTOR		|	OFFSET 15..0	      | <-- EAX
  |_____________________________|_____________________________|


  _____________________________________________________________
  |				| |   | |       | | | |       |
  |  &ignore_int 31..16		|1|000|0| TYPE  |0 0 0| 0000  | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|0|_|_|_|_|_|_|_|
  |				|			      |
  |	      0x0008		|	&ignore_int 15..0     | <-- EAX
  |_____________________________|_____________________________|

*/

setup_idt:
	lea	ignore_int, %edx	# this is the default interrupt handler
	movl	$0x00080000, %eax	# CS = 0x8 - kernel code segment
	movw	%dx, %ax
	movw	$0x8e00, %dx		# present=1, DPL=0, type=14 

	lea	idt, %edi
	mov	$256, %ecx		# 256 descriptors in IDT
rp_sidt:
	movl	%eax, (%edi)
	movl	%edx, 4(%edi)
	addl	$8, %edi
	dec	%ecx
	jne	rp_sidt

	lidt	idt_ptr
	ret

######################################### * Default ISR

ignore_int:
	nop				# do nothing when an interrupt occurs ...
	iret				# just tickle the processor :)

######################################### * Setup IDT

	.balign	8			# align to 8 bytes to increase IDT access speed - (only 1 bus cycle)
idt:	.fill	256, 8, 0		# reserve 256 idt entries - (IDT is not yet initialized!)

idt_ptr:
	.word	256*8 - 1		# Limit: IDT contains 256 entries (8 bytes entries)
	.long	idt			# Base: pointer to the first IDT entry 

######################################### * GDT: granularity = 1 => segment size = limit * 4Kb

	.balign	8
gdt:	.quad	0x0000000000000000	# NULL descriptor!
	.quad	0x00c09a00000007ff	# 8Mb code segment (CS=0x08), base = 0x0000
	.quad	0x00c09200000007ff	# 8Mb data segment (DS=SS=0x10), base = 0x0000
	.quad	0x00c0f20b80000001	# 4Kb video memory (Sel=0x18) - with ** DPL=3! ** 
	.quad	0x0000000000000000	# TSS_SEL
	.quad	0x0000000000000000	# LDT_SEL

gdt_ptr:
	.word	. - gdt -1		# Limit
	.long	gdt			# Base: pointer to the first GDT entry (the NULL descr) 
	

######################################### * the task's purpose

task:
	mov	$0x18, %eax
	mov	%ax, %gs
	xor	%ebx, %ebx
	mov	$'A, %ebx		# print 'A' on the screen
	movb	%bl, %gs:0
	mov	$0x2f, %ebx
	movb	%bl, %gs:1

1:	jmp	1b			# stay here!

