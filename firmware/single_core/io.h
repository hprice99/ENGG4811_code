#ifndef IO_H
#define IO_H

// Character output
#define CHAR_OUTPUT      (*(volatile char*)0x10000000)
#define CHAR_OUTPUT_READY_INPUT      (*(volatile char*)0x10000010)




// Node details
#define MATRIX_INIT_FROM_FILE_INPUT      (*(volatile char*)0x50000000)

// Matrix
#define MATRIX_OUTPUT      (*(volatile long*)0x60000000)
#define MATRIX_END_ROW_OUTPUT      (*(volatile char*)0x60000010)
#define MATRIX_END_OUTPUT      (*(volatile char*)0x60000020)
#define MATRIX_INIT_TYPE_INPUT      (*(volatile char*)0x60000030)
#define MATRIX_INIT_X_COORD_INPUT      (*(volatile char*)0x60000040)
#define MATRIX_INIT_Y_COORD_INPUT      (*(volatile char*)0x60000050)
#define MATRIX_INIT_ELEMENT_INPUT      (*(volatile long*)0x60000060)
#define MATRIX_INIT_READ_OUTPUT      (*(volatile char*)0x60000070)
#define MATRIX_MULTIPLY_DONE_OUTPUT      (*(volatile char*)0x60000080)


#endif