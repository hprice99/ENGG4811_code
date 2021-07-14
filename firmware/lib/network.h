#ifndef NETWORK_H
#define NETWORK_H

#define NETWORK_ERROR   -1
#define NETWORK_SUCCESS 0

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

#ifndef MESSAGE_OUTPUT
#define MESSAGE_OUTPUT              (*(volatile long*)0x20000030)
#endif

#ifndef PACKET_COMPLETE_OUTPUT
#define PACKET_COMPLETE_OUTPUT      (*(volatile char*)0x20000040)
#endif

// Network to PE
#ifndef MESSAGE_VALID_INPUT
#define MESSAGE_VALID_INPUT         (*(volatile char*)0x50000000)
#endif

#ifndef MESSAGE_INPUT
#define MESSAGE_INPUT               (*(volatile long*)0x50000010)
#endif

#ifndef MESSAGE_IN_AVAILABLE_INPUT
#define MESSAGE_IN_AVAILABLE_INPUT  (*(volatile long*)0x50000020)
#endif

int send_message(int dest_x, int dest_y, long message);

int receive_message(long* message);

#endif