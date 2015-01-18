/* 
	main.c

   contains the main function of our system which will invoke:

   1. kernel_init(): to set up TSS and LDT descriptors in GDT and load TR and LDTR.
   2. sti(): to enable interrupts
   3. move_to_user_mode()

   Copyright(C) 2015 Issam Abdallah, Tunisia.
   E-mail: iabdallah@yandex.com
   License GPL
*/

extern long task;	// head.s

#define move_to_user_mode()		\
__asm__ __volatile__(			\
	"movl %%esp,%%eax\n\t" 		\
	"pushl $0x17\n\t" 		\
	"pushl %%eax\n\t" 		\
	"pushfl \n\t" 			\
	"pushl $0x0f\n\t" 		\
	"pushl $1f\n\t" 		\
	"iret\n" 			\
	"1:\tmovl $0x17,%%eax\n\t" 	\
	"movw %%ax,%%ds\n\t" 		\
	"movw %%ax,%%es\n\t" 		\
	"movw %%ax,%%fs\n\t" 		\
	"movw %%ax,%%gs\n" 		\
	"jmp task0"\
	:::"eax")

#define sti() __asm__ __volatile__("\tsti"::)

extern void kernel_init(void);
void main(void);

void main(void)
{

 kernel_init();
 sti();
 move_to_user_mode();

 for(;;){}		// stay here until reboot!
} 

