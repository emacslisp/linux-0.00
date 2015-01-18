#ifndef _HEAD_H
#define _HEAD_H

typedef struct desc_struct {
	unsigned long a,b;
} desc_table[256];

extern desc_table idt;
extern struct desc_struct gdt[6];

#define GDT_NUL 0
#define GDT_CODE 1
#define GDT_DATA 2
#define GDT_VGA 3

#define LDT_NUL 0
#define LDT_CODE 1
#define LDT_DATA 2

#endif
