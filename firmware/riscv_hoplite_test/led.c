#include "led.h"

long createMessage(int node_number, int val) {

    long message = (node_number << 8) | val;

    return message;
}

struct ledMessage decodeMessage(long message) {

    struct ledMessage decoded_message;

    // Message format
    // Bits 0 to 7 - Value
    // Bits 8 to 15 - LED
    decoded_message.value = message & 0xFF;
    decoded_message.led = (message >> 8) & 0xFF;

    return decoded_message;
}
