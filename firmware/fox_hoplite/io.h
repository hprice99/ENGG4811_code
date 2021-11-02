#ifndef IO_H
#define IO_H

// Character output
#define CHAR_OUTPUT      (*(volatile char*)0x10000000)
#define CHAR_OUTPUT_READY_INPUT      (*(volatile char*)0x10000010)

// PE to network
#define MESSAGE_OUT_READY_INPUT      (*(volatile char*)0x20000000)
#define X_COORD_OUTPUT      (*(volatile char*)0x20000010)
#define Y_COORD_OUTPUT      (*(volatile char*)0x20000020)
#define MULTICAST_GROUP_OUTPUT      (*(volatile char*)0x20000030)
#define READY_FLAG_OUTPUT      (*(volatile char*)0x20000040)
#define RESULT_FLAG_OUTPUT      (*(volatile char*)0x20000050)
#define MATRIX_TYPE_OUTPUT      (*(volatile char*)0x20000060)
#define MATRIX_X_COORD_OUTPUT      (*(volatile char*)0x20000070)
#define MATRIX_Y_COORD_OUTPUT      (*(volatile char*)0x20000080)
#define MATRIX_ELEMENT_OUTPUT      (*(volatile long*)0x20000090)
#define PACKET_COMPLETE_OUTPUT      (*(volatile char*)0x20000100)

// LEDs
#define LED_OUTPUT      (*(volatile char*)0x30000000)

// Network to PE
#define MESSAGE_VALID_INPUT      (*(volatile char*)0x40000000)
#define MESSAGE_IN_AVAILABLE_INPUT      (*(volatile char*)0x40000010)
#define MULTICAST_GROUP_INPUT      (*(volatile char*)0x40000020)
#define READY_FLAG_INPUT      (*(volatile char*)0x40000030)
#define RESULT_FLAG_INPUT      (*(volatile char*)0x40000040)
#define MATRIX_TYPE_INPUT      (*(volatile char*)0x40000050)
#define MATRIX_X_COORD_INPUT      (*(volatile char*)0x40000060)
#define MATRIX_Y_COORD_INPUT      (*(volatile char*)0x40000070)
#define MATRIX_ELEMENT_INPUT      (*(volatile long*)0x40000080)
#define MESSAGE_READ_OUTPUT      (*(volatile char*)0x40000090)

// Node details
#define X_COORD_INPUT      (*(volatile char*)0x50000000)
#define Y_COORD_INPUT      (*(volatile char*)0x50000010)
#define NODE_NUMBER_INPUT      (*(volatile char*)0x50000020)
#define MATRIX_X_OFFSET_INPUT      (*(volatile char*)0x50000030)
#define MATRIX_Y_OFFSET_INPUT      (*(volatile char*)0x50000040)
#define MATRIX_INIT_FROM_FILE_INPUT      (*(volatile char*)0x50000050)

// Matrix
#define MATRIX_OUTPUT      (*(volatile long*)0x60000000)
#define MATRIX_END_ROW_OUTPUT      (*(volatile char*)0x60000010)
#define MATRIX_END_OUTPUT      (*(volatile char*)0x60000020)
#define FOX_MATRIX_SIZE_INPUT      (*(volatile long*)0x60000030)

// Network details
#define FOX_NETWORK_STAGES_INPUT      (*(volatile char*)0x70000000)
#define RESULT_X_COORD_INPUT      (*(volatile char*)0x70000010)
#define RESULT_Y_COORD_INPUT      (*(volatile char*)0x70000020)
#define ROM_X_COORD_INPUT      (*(volatile char*)0x70000030)
#define ROM_Y_COORD_INPUT      (*(volatile char*)0x70000040)

#endif