#include "io.h"
#include "print.h"

// #define LOOP_DELAY 1000000000
#define LOOP_DELAY 0
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

    char message[] = "$Uryyb+Jbeyq!+Vs+lbh+pna+ernq+guvf+zrffntr+gura$gur+CvpbEI32+PCH"
            "+frrzf+gb+or+jbexvat+whfg+svar.$$++++++++++++++++GRFG+CNFFRQ!$$";
    for (int i = 0; message[i]; i++)
        switch (message[i])
        {
        case 'a' ... 'm':
        case 'A' ... 'M':
            message[i] += 13;
            break;
        case 'n' ... 'z':
        case 'N' ... 'Z':
            message[i] -= 13;
            break;
        case '$':
            message[i] = '\n';
            break;
        case '+':
            message[i] = ' ';
            break;
        }
    print_string(message);

    unsigned long loopCount = 0;
    int currentLed = 0;

    while (1) {

        loopCount++;

        if (loopCount > LOOP_DELAY) {

            ledValues[currentLed] = 1 - ledValues[currentLed];

            setLeds(currentLed, ledValues[currentLed]);

            currentLed++;

            if (currentLed >= LED_COUNT) {

                currentLed = 0;
            }

            loopCount = 0;
        }
    }
}
