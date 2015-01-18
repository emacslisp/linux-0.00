/* kernel.c

   kernel.c is a modification of linux-0.01/sched.c. 

   copyright(C) 2015 Issam Abdallah-Tunisia.
   E-mail: iabdallah@yandex.com
   License GPL

*/

#include "kernel.h"
#include "io.h"

#define STACK_SIZE (1024) 		/* 104 bytes for TSS */

long task0_stack [ STACK_SIZE>>2 ];	/* in .bss */
long task1_stack [ STACK_SIZE>>2 ];	/* in .bss */

long kernel_stack [ STACK_SIZE>>2 ];	/* in .bss */

struct {
	long * a;	// esp
	short b;	// ss
} stack_start = 
	{ &kernel_stack [STACK_SIZE>>2], // ESP0
	  0x10 				// SS0
	}; // used by LSS in head.s


union task_union {	// max=STACK_SIZE - min=104 bytes
	struct task_struct task;
	char stack[STACK_SIZE];
};

static union task_union init_task = {TASK0, };	// 'task0'
static union task_union second_task = {TASK1, };	// 'task1'

extern void system_call(void);
extern void timer_interrupt (void);

void schedule (void)
{
   if(current==0)
   {
	current=1;			   	  
	switch_to(1);	
   }
   if(current==1)
   {
	current=0;
	switch_to(0);
   }
} 

void sys_write(char msg, char attr)
{
  vga_ptr[char_pos++] = (char)msg;
  vga_ptr[char_pos++] = (char)attr;
  if(char_pos==VGA_MEM)
	char_pos=0;
}

void kernel_init(void)
{
  set_tss_desc(&gdt[FIRST_TSS_ENTRY],&(init_task.task.tss));
  set_ldt_desc(&gdt[FIRST_LDT_ENTRY],&(init_task.task.ldt));

  set_tss_desc(&gdt[2+FIRST_TSS_ENTRY], &(second_task.task.tss));
  set_ldt_desc(&gdt[2+FIRST_LDT_ENTRY], &(second_task.task.ldt));

  ltr(0);
  lldt(0);

/* programming the timer chip 
 * - I/O ports:

	0x40	     Channel 0 data port (read/write) (IRQ0)
	0x41         Channel 1 data port (read/write)
	0x42         Channel 2 data port (read/write)
	0x43         Mode/Command register (write only, a read is ignored)
	
   - Output 0 (channel 0) is connected to pin 0 of the 8259A PIC: timer interrupt (IRQ0)

   - Mode/Command register (port 0x43)

	 ___7_____6__ __5____4___ __3_____2_____1_____0___
	 |     |     |     |     |     |     |     | BCD/ |   
	 |  channel  |Access mode| Operating mode  | BIN  |
	 |_____|_____|_____|_____|_____|_____|_____|_mode_| 

*/
  outb_p(0x36, 0x43);		/* binary, mode 3, LSB/MSB, ch 0 */
  outb_p(LATCH & 0xff , 0x40);	/* LSB */
  outb(LATCH >> 8 , 0x40);	/* MSB */

/* setup timer interrupt gate descriptor */
  set_intr_gate(0x20, &timer_interrupt);
/* unmask the timer interrupt */
  outb(inb_p(0x21)&~0x01, 0x21);
/* setup system call gate descriptor at IDT[0x80] */
  set_system_gate(0x80, &system_call);

  vga_ptr = (char*)(0xb8000);
  char_pos=0;
  current=0;
}

