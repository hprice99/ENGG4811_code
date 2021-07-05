#ifndef IO_H
#define IO_H

#define CHAR_OUTPUT (*(volatile char*)0x10000000)
#define LED (*(volatile char*)0x20000000)
#define SWITCH (*(volatile char*)0x30000000)

#define MATRIX_ROW_END (*(volatile char*)0x50000000)
#define MATRIX_END (*(volatile char*)0x60000000)
#define MATRIX_POSITION (*(volatile char*)0x70000000)
#define MATRIX_OUTPUT (*(volatile long*)0x80000000)

#endif