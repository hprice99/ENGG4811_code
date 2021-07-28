#ifndef NETWORK_H
#define NETWORK_H

#include <stdbool.h>

enum NetworkError {
    NETWORK_SUCCESS             ,
    NETWORK_ERROR               ,
    NETWORK_MESSAGE_UNAVAILABLE 
};

#ifdef IO_CONFIG
#include "io.h"
#endif

// PE to network
#ifndef MESSAGE_OUT_READY_INPUT
#define MESSAGE_OUT_READY_INPUT     (*(volatile char*)0x20000000)
#endif

#ifndef X_COORD_OUTPUT
#define X_COORD_OUTPUT              (*(volatile char*)0x20000010)
#endif

#ifndef Y_COORD_OUTPUT
#define Y_COORD_OUTPUT              (*(volatile char*)0x20000020)
#endif

#ifndef MULTICAST_GROUP_OUTPUT
#define MULTICAST_GROUP_OUTPUT      (*(volatile char*)0x20000030)
#endif

#ifndef DONE_FLAG_OUTPUT
#define DONE_FLAG_OUTPUT            (*(volatile char*)0x20000040)
#endif

#ifndef RESULT_FLAG_OUTPUT
#define RESULT_FLAG_OUTPUT          (*(volatile char*)0x20000050)
#endif

#ifndef MATRIX_TYPE_OUTPUT
#define MATRIX_TYPE_OUTPUT          (*(volatile char*)0x20000060)
#endif

#ifndef MATRIX_X_COORD_OUTPUT
#define MATRIX_X_COORD_OUTPUT       (*(volatile char*)0x20000070)
#endif

#ifndef MATRIX_Y_COORD_OUTPUT
#define MATRIX_Y_COORD_OUTPUT       (*(volatile char*)0x20000080)
#endif

#ifndef MATRIX_ELEMENT_OUTPUT
#define MATRIX_ELEMENT_OUTPUT       (*(volatile long*)0x20000090)
#endif

#ifndef PACKET_COMPLETE_OUTPUT
#define PACKET_COMPLETE_OUTPUT      (*(volatile char*)0x20000040)
#endif

// Network to PE
#ifndef MESSAGE_VALID_INPUT
#define MESSAGE_VALID_INPUT         (*(volatile char*)0x50000000)
#endif

#ifndef MESSAGE_IN_AVAILABLE_INPUT
#define MESSAGE_IN_AVAILABLE_INPUT  (*(volatile long*)0x50000010)
#endif

#ifndef MULTICAST_GROUP_INPUT
#define MULTICAST_GROUP_INPUT       (*(volatile char*)0x50000020)
#endif

#ifndef DONE_FLAG_INPUT
#define DONE_FLAG_INPUT             (*(volatile char*)0x50000030)
#endif

#ifndef RESULT_FLAG_INPUT
#define RESULT_FLAG_INPUT           (*(volatile char*)0x50000040)
#endif

#ifndef MATRIX_TYPE_INPUT
#define MATRIX_TYPE_INPUT           (*(volatile char*)0x50000050)
#endif

#ifndef MATRIX_X_COORD_INPUT
#define MATRIX_X_COORD_INPUT        (*(volatile char*)0x50000060)
#endif

#ifndef MATRIX_Y_COORD_INPUT
#define MATRIX_Y_COORD_INPUT        (*(volatile char*)0x50000070)
#endif

#ifndef MATRIX_ELEMENT_INPUT
#define MATRIX_ELEMENT_INPUT        (*(volatile long*)0x50000080)
#endif

#ifndef MESSAGE_READ_OUTPUT
#define MESSAGE_READ_OUTPUT         (*(volatile char*)0x50000090)
#endif

enum MatrixType {
    A_type = 0, 
    B_type = 1
};

struct MatrixPacket {
    int destX;
    int destY;
    int multicastGroup;
    bool doneFlag;
    bool resultFlag;
    enum MatrixType matrixType;
    int matrixX;
    int matrixY;
    long matrixElement;
};

struct MatrixPacket create_matrix_packet(int destX, int destY, 
        int multicastGroup, bool doneFlag, bool resultFlag, 
        enum MatrixType matrixType, int matrixX, int matrixY, 
        long matrixElement);

void print_matrix_packet(char* caller, struct MatrixPacket packet);

enum NetworkError send_message(struct MatrixPacket packet);

enum NetworkError receive_message(struct MatrixPacket* packet);

#endif