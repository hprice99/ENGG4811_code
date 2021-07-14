#include "io.h"
#include "print.h"
#include "network.h"

#include "firmware_riscv_hoplite_test_led.h"

#define LOOP_DELAY 1000000000
#define NUM_DELAYS 50000
// #define LOOP_DELAY 2
#define LED_COUNT 4

int ledValues[LED_COUNT] = {0, 0, 0, 0};

int my_x_coord;
int my_y_coord;
int my_node_number;

int switchState;

long createMessage(int val) {

    long message = (my_node_number << 8) | val;

    return message;
}

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

void loopLeds(void) {

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

struct ledMessage decodeMessage(long message) {

    struct ledMessage decoded_message;

    // Message format
    // Bits 0 to 7 - Value
    // Bits 8 to 15 - LED
    decoded_message.value = message & 0xFF;
    decoded_message.led = (message >> 8) & 0xFF;

    return decoded_message;
}

void main() {

    print_string("ENGG4811 PicoRV32 test\n");

    // Read node coordinates from hardware and print
    my_x_coord = X_COORD_INPUT;
    my_y_coord = Y_COORD_INPUT;
    my_node_number = NODE_NUMBER_INPUT;

    print_string("Node coordinates (");
    print_hex(my_x_coord, 1);
    print_string(", ");
    print_hex(my_y_coord, 1);
    print_string("), node number = ");
    print_hex(my_node_number, 1);

    // loopLeds();

    int network_error;
    long message_to_send;
    long message_received;
    struct ledMessage decoded_message;

    switchState = SWITCH_INPUT;

    while (1) {

        // Switch flipped
        if (SWITCH_INPUT != switchState) {

            switchState = SWITCH_INPUT;

            // Create message
            message_to_send = createMessage(switchState);

            // Send message
            network_error = send_message(LED_X, LED_Y, message_to_send);

            if (network_error != NETWORK_SUCCESS) {

                print_string("Unable to send message\n");
            } else {

                print_string("Message sent ");
                print_hex(message_to_send, 4);
            }
        }

        network_error = receive_message(&message_received);

        if (network_error == NETWORK_SUCCESS) {

            print_string("Message received ");
            print_hex(message_received, 4);

            // Decode message
            decoded_message = decodeMessage(message_received);

            print_string("Setting LED ");
            print_hex(decoded_message.led, 1);
            print_string(" to value ");
            print_hex(decoded_message.value, 1);

            // Set LEDs
            setLeds(decoded_message.led, decoded_message.value);
        }
    }
}
