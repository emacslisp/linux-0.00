/*
*	system_call.s
*
*   copyright(C) 2015 Issam Abdallah-Tunisia.
*   E-mail: iabdallah@yandex.com
*   License GPL
*
*/
	.global system_call, task

	.balign 2
system_call:

	push	%eax
	push	%ds
	push	%gs
	push	%ebx

	mov	$0x10, %eax		# DS points to kernel data
	mov	%ax, %ds

	mov	$0x18, %eax		# GDT[3] - video memory descriptor (DPL=0)
	mov	%ax, %gs

	xor	%ebx, %ebx
	mov	$'A, %ebx		# print 'A' on the screen
	movb	%bl, %gs:0
	mov	$0x2f, %ebx
	movb	%bl, %gs:1

	pop	%ebx
	pop	%gs
	pop	%ds
	pop	%eax
	iret

	.balign 2
task:
	int	$0x80			# system call
1:	jmp	1b			# stay here!
