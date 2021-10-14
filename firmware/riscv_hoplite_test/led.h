#ifndef LED_H
#define LED_H

#define LED_X   0
#define LED_Y   0

struct ledMessage {
    int led;
    int value;
};

struct ledMessage decodeMessage(long message);

long createMessage(int node_number, int val);

#endif