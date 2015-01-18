 /* 
	kernel.s 

   A 32 bit code, running in 386 protected mode. It will setup IDT, GDT, 
   segment registres, enable interrupts and transfer the control 
   to a user mode (level 3) task which will just print 'A' on
   the screen by calling a system call.

   copyright(C) 2015 Issam Abdallah, Tunisia.
   E-mail: iabdallah@yandex.com

   License: GPL

*/

TSS_SEL = 0x20
LDT_SEL = 0x28

	.global	startup_32
	.text

startup_32:

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	kern_stack_ptr, %esp	# load SS and ESP


######################################### * setup base fields of descriptors 5 and 6 in GDT

	lea	gdt, %ecx		# LEA: load effective address

	lea	tss, %eax
	movl	$TSS_SEL, %edi		# TSS_SEL = 0x20
	call	set_tssldt_des

	lea	ldt, %eax
	movl	$LDT_SEL, %edi		# LDT_SEL = 0x28
	call	set_tssldt_des

######################################### * setup GDT and IDT

	call	setup_idt
	call	setup_gdt

#########################################

	mov 	$0x10, %eax 		# data segment - Selctor 0x10
	mov 	%ax, %ds
	mov 	%ax, %es
	mov 	%ax, %fs 
	mov 	%ax, %gs
	lss	kern_stack_ptr, %esp

######################################### * setup system call gate descriptor

	call	set_system_gate

######################################### * Move to user mode (task)
## NOTE: IRET will cause the processor to automatically switch to another task if NT=1! 

	pushfl
	andl	$0xffffbfff, (%esp)	# ensure that NT is clear (NT = 0)! 
	popfl

	movl	$TSS_SEL, %eax
	ltr	%ax			# Load task register
	movl	$LDT_SEL, %eax
	lldt	%ax 			# load LDTR

	sti				# IDT is setup, so we can enable interrupts now
 
######################################### * stack layout before IRET with privilege transition - see 80386's manual!

	pushl	$0x17			# task's SS
	pushl	$stack_ptr		# task's ESP
	pushfl				# task's EFLAGS
	pushl	$0x0f			# task's CS
	pushl	$task			# task's EIP

######################################### move to user mode and execute the task by loading EIP, CS, EFLAGS, ESP and SS 
					# by the values previously pushed into the stack
	iret				 
					
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

/* system call 

		Trap gate descriptor (type=15 = 0xF)
  _____________________________________________________________
  |				| |   | |       | | | |       |
  |	   OFFSET 31..16	|P|DPL|0| TYPE  |0 0 0|unused | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|1|_|_|_|_|_|_|_|
  |				|			      |
  |	      SELECTOR		|	OFFSET 15..0	      | <-- EAX
  |_____________________________|_____________________________|

  _____________________________________________________________
  |				| |   | |       | | | |       |
  |  &system_call 31..16	|1|1 1|0| TYPE  |0 0 0| 0000  | <-- EDX
  |_____________________________|_|_|_|_|1|1|1|1|_|_|_|_|_|_|_|
  |				|			      |
  |	      0x0008		|	&system_call 15..0    | <-- EAX
  |_____________________________|_____________________________| <-- idt[0x80]

*/
set_system_gate:
	movl	$0x80, %ecx
	lea	idt(,%ecx,8), %edi	# IDT[0x80]: system call gate
	mov	$0x80000, %eax		# CS = 0x8
	lea	system_call, %edx

	mov	%dx, %ax
	mov	%eax, (%edi)
	mov	$0xef00, %dx		# interrupt gate: Present, DPL=3, type=15
	mov	%edx, 4(%edi)
	ret

######################################### * Default ISR

ignore_int:
	nop				# do nothing when an interrupt occurs ...
	iret				# just tickle the processor :)

######################################### * This proc will set the bases fileds
					# of TSS and LDT descriptors in GDT with
					# the adresses 'tss' and 'ldt' at runtime.
set_tssldt_des:

	addl	%ecx, %edi		# ECX = gdt
	movw	%ax, 2(%edi)		# base 0..15
	rorl	$16, %eax
	movb	%al, 4(%edi)		# base 16..23
	movb	%ah, 7(%edi)		# base 31..24
	ret

#########################################

	.balign	2
system_call:
	push	%eax
	push	%gs
	push	%ecx
	push	%edx

	mov	$0x18, %eax		# GDT[3] - video memory
	mov	%ax, %gs

	mov	$'A, %ecx		# print 'A'
	movb	%cl, %gs:0
	mov	$0x2f, %edx	
	movb	%dl, %gs:1

	pop	%edx
	pop	%ecx
	pop	%gs
	pop	%eax
	iret

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
	.quad	0x00c0920b80000001	# 4Kb video memory (Sel=0x18) - with ** DPL=0! ** 
	.quad	0x0000890000000068	# TSS descriptor (Selector = 0x20) - Granularity = 0
	.quad	0x0000820000000040	# LDT descr (Selector = 0x28) - Granularity = 0

gdt_ptr:
	.word	. - gdt -1		# Limit
	.long	gdt			# Base: pointer to the first GDT entry (the NULL descr) 
	
######################################### * kernel stack (level-0)

	.balign	4
	.fill 128, 4, 0			# reserve 32 words for the kernel stack
kern_stack_ptr:
	.long .				# ESP
	.word 0x10			# SS

######################################### * the task's LDT

	.balign 8
ldt:	.quad	0x0000000000000000
	.quad	0x00c0fa00000007ff	# the task's local code segment (CS = 0x0f)
	.quad	0x00c0f200000007ff	# the task's local data segment (DS = SS = 0x17)

######################################### * the task's TSS

tss:
	.long	0 			# back link = 0 (no previous TSS)
	.long	stack_ptr0		# esp0
	.long	0x10			# ss0
	.long	0			# esp1
	.long	0			# ss1
	.long	0			# esp2
	.long	0			# ss2 
	.long	0			# cr3 (paging is disabled!)
	.long	task			# eip
	.long	0x200			# eflags
	.long	0, 0, 0, 0		# eax, ecx, edx, ebx
	.long	stack_ptr		# esp (level 3 stack pointer)
	.long	0, 0, 0			# ebp, esi, edi 
	.long	0x17			# es
	.long   0x0f			# cs
	.long	0x17			# ss (level 3 stack)
	.long	0x17,0x17,0x17		# ds, fs, gs
	.long	LDT_SEL			# ldt selector
	.long	0x8000000		# I/O map base + T-bit

task_stack0:
	.fill	128,4,0
stack_ptr0:				# task is ESP0

######################################### * the task's purpose

task:
	int	$0x80
1:	jmp	1b			# stay here!

######################################### * the task's level-3 stack

task_stack:
	.fill	128,4,0
stack_ptr:				# ESP3


