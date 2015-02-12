#ifndef _KERNEL_H
#define _KERNEL_H

#include "head.h"

#define TIMER_FREQ 1193180	/* timer (INTEL 8253 PIT) oscillator frequency */
#define HZ 100			/* 100 timer interrupts per second */

#define LATCH (TIMER_FREQ/HZ)   /* The timer will decrement by one this value each T = 0.000838 ms.
				 When it becomes equal to 0, the PIT will generate a timer interrupt (IRQ0)*/

/* video mode: 80x25 16 colors text mode.
 * That is, we can display only 2000 characters ('A' and 'B') at once.
*/
#define SCREEN	2000

/* 
* To be displayed, each character will take 2 bytes in the VGA memory
* 1 byte to write its ASCII code (even adresses: 0, 2, 4, 6,...)- 
* 1 byte to write its attribute (odd adresses:     1, 3, 5 ,7,...)
* That is, we will use 4000 bytes in the VGA memory.
*/
#define VGA_MEM SCREEN*2

extern long task0;
extern long task1;

char * vga_ptr;
int char_pos;
int current;

void schedule (void);
void sys_write(char msg, char attr);
void kernel_init(void);

struct tss_struct {
	long	back_link;	
	long	esp0;
	long	ss0;
	long	esp1;
	long	ss1;
	long	esp2;
	long	ss2;
	long	cr3;
	long	eip;
	long	eflags;
	long	eax,ecx,edx,ebx;
	long	esp;
	long	ebp;
	long	esi;
	long	edi;
	long	es;
	long	cs;
	long	ss;
	long	ds;
	long	fs;
	long	gs;
	long	ldt;
	long	trace_bitmap;
};

struct task_struct {
/* ldt for this task 0 - NULL 1 - cs 2 - ds&ss */
	struct desc_struct ldt[3];
/* tss for this task */
	struct tss_struct tss;
};

/* task0 */
#define TASK0			\
{				\
/*ldt*/	{ 			\
	 {0,0}, 		\
/*code*/ {0x7ff,0x00c0fa00}, 	\
/*data*/ {0x7ff,0x00c0f200}	\
	},			\
/*tss*/	{			\
/* back link*/	0,		\
/* esp0 */	STACK_SIZE+(long)&init_task,\
/* ss0 */	0x10,		\
/* esp1 */	0,		\
/* ss1 */	0,		\
/* esp2 */	0,		\
/* ss2 */	0,		\
/* cr3 */	0,		\
/* eip */	(long)&task0,	\
/*eflags*/	0,		\
/*eax, ecx,*/	0,0,0,0,	\
/* esp */	(long)&task0_stack[STACK_SIZE>>2], \
/*ebp,esi,edi*/	0,0,0,		\
/* es */	0x17,		\
/* cs*/		0x0f,		\
/* ss */	0x17,		\
/* ds,fs,gs */	0x17,0x17,0x17,	\
/* LDT*/	LDT(0),		\
	 	0x80000000	\
	}			\
}

/* task1 */
#define TASK1			\
{				\
/*ldt*/	{ 			\
	 {0,0}, 		\
/*code*/ {0x7ff,0x00c0fa00}, 	\
/*data*/ {0x7ff,0x00c0f200}	\
	},			\
/*tss*/	{					\
/* back link*/	0,				\
/* esp0 */	STACK_SIZE+(long)&second_task,	\
/* ss0 */	0x10,				\
/* esp1 */	0,				\
/* ss1 */	0,				\
/* esp2 */	0,				\
/* ss2 */	0,				\
/* cr3 */	0,				\
/* eip */	(long)&task1,			\
/*eflags*/	0x200,				\
/*eax, ecx,*/	0,0,0,0,			\
/* esp */	(long)&task1_stack[STACK_SIZE>>2],\
/*ebp,esi,edi*/	0,0,0,				\
/* es */	0x17,				\
/* cs*/		0x0f,				\
/* ss */	0x17,				\
/* ds,fs,gs */	0x17,0x17,0x17,			\
/* LDT*/	LDT(1),				\
	 	0x80000000			\
	}					\
}

/*
 * Entry into gdt where to find first TSS. 0-nul, 1-cs, 2-ds, 3-syscall
 * 4-TSS0, 5-LDT0, 6-TSS1 etc ...
 */
#define FIRST_TSS_ENTRY 4
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY+1)
#define TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
#define LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))

#define ltr(n)			\
 __asm__ __volatile__(		\
	"ltr %%ax"		\
	 ::"a" (TSS(n)))

#define lldt(n)			\
__asm__ __volatile__(		\
	"lldt %%ax"		\
	 ::"a" (LDT(n)))

/* switch_to(n) should switch tasks to task n. */

#define switch_to(n)		  \
{				  \
struct {long a,b;} __tmp; 	  \
__asm__ __volatile__(		  \
	"movw %%dx,%1\n\t"	  \
	"ljmp *%0\n\t" 		  \
	"1:" 			  \
	::"m" (*&__tmp.a),	  \
	  "m" (*&__tmp.b), 	  \
	"d" TSS(n));		  \
}

/*		
	System segment descriptor
  _____________________________________________________________
  |		| | | |A| Limit	| |   | |       |             |
  | BASE 31..24 |G|X|0|V|19..16	|P|DPL|0| TYPE  | Base 23..16 | <-- EDX
  |_____________|_|_|_|L|_______|_|_|_|_|_______|_____________|
  |				|			      |
  |	     BASE 15..0		|	LIMIT 15..0	      | <-- EAX
  |_____________________________|_____________________________|

     LDT - type = 0x2
     Available 386 TSS - type = 0x9 

*/

#define _set_tssldt_desc(n,addr,type)	\
__asm__ __volatile__(			\
	"movw $104,%1\n\t" 		\
	"movw %%ax,%2\n\t" 		\
	"rorl $16,%%eax\n\t" 		\
	"movb %%al,%3\n\t" 		\
	"movb $" type ",%4\n\t" 	\
	"movb $0x00,%5\n\t" 		\
	"movb %%ah,%6\n\t" 		\
	"rorl $16,%%eax" 		\
					\
	::"a" (addr), "m" (*(n)),	\
	  "m" (*(n+2)), "m" (*(n+4)), 	\
	 "m" (*(n+5)), "m" (*(n+6)),	\
	 "m" (*(n+7)): "cc")

#define set_tss_desc(n,addr) _set_tssldt_desc(((char *) (n)),addr,"0x89") // TSS
#define set_ldt_desc(n,addr) _set_tssldt_desc(((char *) (n)),addr,"0x82") // LDT

/* setup system call gate descriptor at IDT[0x80]
 We are in Level 3 and we want to call a kernel routine at level 0
 using the instruction 'int'. INTEL 80386 Manual/section 6.4.3:

 	"To provide protection for control transfers among 
 	executable segments at different privilege levels, 
 	the 80386 uses gate descriptors."
 
 That is, We can do that through a 'Trap gate' as it's done on linux-0.01. 

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

#define set_system_gate(n,addr) _set_gate(&idt[n],15,3,addr)

#define _set_gate(gate_addr,type,dpl,addr)		\
__asm__ __volatile__(					\
	"movw %%dx,%%ax\n\t"				\
	"movw %0,%%dx\n\t"				\
	"movl %%eax,%1\n\t"				\
	"movl %%edx,%2"					\
	: 						\
	: "i" ((short) (0x8000+(dpl<<13)+(type<<8))), 	\
	"o" (*((char *) (gate_addr))), 			\
	"o" (*(4+(char *) (gate_addr))), 		\
	"d" ((char *) (addr)),"a" (0x00080000))

#define set_intr_gate(n,addr) _set_gate(&idt[n],14,0,addr) // to set up timer interrupt

#endif 
