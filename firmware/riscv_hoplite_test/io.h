#ifndef IO_H
#define IO_H

#define CHAR_OUTPUT     (*(volatile char*)0x10000000)

// PE to network
#define X_COORD_OUTPUT          (*(volatile char*)0x20000000)
#define Y_COORD_OUTPUT          (*(volatile char*)0x20000010)
#define MESSAGE_OUTPUT          (*(volatile long*)0x20000020)
#define PACKET_COMPLETE_OUTPUT  (*(volatile char*)0x20000030)

// LEDs
#define LED_0_OUTPUT    (*(volatile char*)0x30000000)
#define LED_1_OUTPUT    (*(volatile char*)0x30000010)
#define LED_2_OUTPUT    (*(volatile char*)0x30000020)
#define LED_3_OUTPUT    (*(volatile char*)0x30000030)

#define SWITCH_INPUT            (*(volatile char*)0x40000000)

// Network to PE
#define MESSAGE_VALID_INPUT     (*(volatile char*)0x50000000)
#define MESSAGE_INPUT           (*(volatile long*)0x50000010)

#endif