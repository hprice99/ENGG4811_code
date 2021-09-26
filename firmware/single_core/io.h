#ifndef IO_H
#define IO_H

// Character output
#define CHAR_OUTPUT      (*(volatile char*)0x10000000)
#define CHAR_OUTPUT_READY_INPUT      (*(volatile char*)0x10000010)


// LEDs
#define LED_OUTPUT      (*(volatile char*)0x30000000)


// Node details
#define MATRIX_INIT_FROM_FILE_INPUT      (*(volatile char*)0x50000000)

// Matrix
#define MATRIX_OUTPUT      (*(volatile long*)0x60000000)
#define MATRIX_END_ROW_OUTPUT      (*(volatile char*)0x60000010)
#define MATRIX_END_OUTPUT      (*(volatile char*)0x60000020)


#endif