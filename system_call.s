/*
*	system_call.s
*
*   contains system_call and timer interrupt handlers.
*
*   Stack Layout after Exception or Interrupt with privilege transition: 
*
*	0x0(%esp) - %eip
*	0x4(%esp) - %cs
*	0x8(%esp) - %eflags
*	0xC(%esp) - %oldesp
*	0x10(%esp) - %oldss

*   copyright(C) 2015 Issam Abdallah-Tunisia.
*   E-mail: iabdallah@yandex.com
*   License GPL
*
*/
	.global system_call, timer_interrupt, task0, task1

	.balign 2
system_call:

	push	%ds
	push	%eax

	mov	$0x10, %eax		# DS points to kernel data
	mov	%ax, %ds

	push	%edx			# %edx and %ecx are the parameters to be passed to the system call
	push	%ecx
	call	sys_write
	add	$8, %esp		# clean the stack

	pop	%eax
	pop	%ds
	iret

	.balign	2

timer_interrupt:
	push	%ds
	push	%eax

	movl	$0x10, %eax
	mov	%ax, %ds

	movb	$0x20, %al		# EOI to interrupt controller
	outb 	%al, $0x20

	call 	schedule		# kernel.c

	pop	%eax
	pop	%ds
	iret

	.balign 2
task0:
	mov	$'A, %ecx		# print 'A'
	mov	$0x2f, %edx
	int	$0x80			# system call
	jmp	task0

	.balign 2
task1:
	mov	$'B, %ecx		# print 'A'
	mov	$0x1f, %edx
	int	$0x80			# system call
	jmp	task1

