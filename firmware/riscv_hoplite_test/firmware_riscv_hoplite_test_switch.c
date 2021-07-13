#include "io.h"
#include "print.h"
#include "network.h"

#include "firmware_riscv_hoplite_test_switch.h"

int my_x_coord;
int my_y_coord;
int my_node_number;

int switchState;

long createMessage(int val) {

    long message = (my_node_number << 8) | val;

    return message;
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

    switchState = SWITCH_INPUT;

    int network_error;
    long message;

    while (1) {

        // Switch flipped
        if (SWITCH_INPUT != switchState) {

            switchState = SWITCH_INPUT;

            // Create message
            message = createMessage(switchState);

            // Send message
            network_error = send_message(LED_X, LED_Y, message);

            if (network_error != NETWORK_SUCCESS) {

                print_string("Unable to send message\n");
            } else {

                print_string("Message sent ");
                print_hex(message, 4);
            }
        }
    }
}
