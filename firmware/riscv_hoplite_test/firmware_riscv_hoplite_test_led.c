#include "io.h"
#include "print.h"

#define LOOP_DELAY 1000000000
// #define NUM_DELAYS 1000000000
#define NUM_DELAYS 500
// #define LOOP_DELAY 2
#define LED_COUNT 4

int ledValues[LED_COUNT] = {0, 0, 0, 0};

void setLeds(int led, int value) {

    switch (led) {

        case 0:
            LED_0_OUTPUT = value;
            break;
        case 1:
            LED_1_OUTPUT = value;
            break;
        case 2:
            LED_2_OUTPUT = value;
            break;
        case 3:
            LED_3_OUTPUT = value;
            break;
        default:
            break;
    }
}

void main() {

    print_string("ENGG4811 PicoRV32 test\n");

    // TODO Read node coordinates from hardware and print

    unsigned long loopCount = 0;
    unsigned long delayCount = 0;
    int currentLed = 0;

    // 0 - LED0 to LED3, 1 - LED3 to LED0
    int direction = 0;

    while (1) {

        loopCount++;

        if (loopCount > LOOP_DELAY) {

            delayCount++;

            if (delayCount > NUM_DELAYS) {

                ledValues[currentLed] = 1 - ledValues[currentLed];
                setLeds(currentLed, ledValues[currentLed]);

                print_string("Current LED: ");
                print_hex(currentLed, 1);
                print_string("\n");

                if (direction == 0) {

                    currentLed++;

                    if (currentLed >= LED_COUNT) {

                        direction = 1; 
                        currentLed = LED_COUNT - 1;
                    }
                } else {

                    currentLed--;

                    if (currentLed < 0) {

                        direction = 0;
                        currentLed = 0;
                    }
                }

                delayCount = 0;
            }

            loopCount = 0;
        }
    }
}
