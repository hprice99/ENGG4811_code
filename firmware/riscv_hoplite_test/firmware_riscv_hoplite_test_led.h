#ifndef FIRMWARE_RISCV_HOPLITE_TEST_LED_H
#define FIRMWARE_RISCV_HOPLITE_TEST_LED_H

#define LED_X   0
#define LED_Y   0
struct ledMessage {
    int led;
    int value;
};

struct ledMessage decodeMessage(long message);

#endif