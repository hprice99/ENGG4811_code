#ifndef FIRMWARE_RISCV_HOPLITE_TEST_LED_H
#define FIRMWARE_RISCV_HOPLITE_TEST_LED_H

struct ledMessage {
    int led;
    int value;
};

struct ledMessage decodeMessage(long message);

#endif