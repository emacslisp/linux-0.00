/* kernel.c

   kernel.c is a modification of linux-0.01/sched.c. 
   
   copyright(C) 2015 Issam Abdallah-Tunisia.
   E-mail: iabdallah@yandex.com
   License GPL

*/

#include "kernel.h"

#define STACK_SIZE (1024) 		/* 104 bytes for TSS */

long task_stack0 [ STACK_SIZE>>2 ];	/* in .bss */
long task_stack3 [ STACK_SIZE>>2 ];	/* in .bss */

struct {
	long * a;	// esp
	short b;	// ss
} stack_start = 
	{ &task_stack0 [STACK_SIZE>>2], // ESP0
	  0x10 				// SS0
	}; // used by LSS in head.s


union task_union {	// max=STACK_SIZE - min=104 bytes
	struct task_struct task;
	char stack[STACK_SIZE];
};

static union task_union init_task = {INIT_TASK,};	// init_task is our task 'task'

extern void system_call(void);

void kernel_init(void)
{
  set_tss_desc(&gdt[FIRST_TSS_ENTRY],&(init_task.task.tss));
  set_ldt_desc(&gdt[FIRST_LDT_ENTRY],&(init_task.task.ldt));

  ltr(0);
  lldt(0);

/* setup system call gate descriptor at IDT[0x80] */
  set_system_gate(0x80, &system_call);
}
