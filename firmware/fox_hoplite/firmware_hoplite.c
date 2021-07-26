#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "network.h"

#include <stdbool.h>

#define LOOP_DELAY 40000000

int my_x_coord;
int my_y_coord;
int my_node_number;

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

    fox_stages = FOX_NETWORK_STAGES_INPUT;
    print_string(", Fox stages = ");
    print_hex(fox_stages, 1);
    print_string("\n");

    int ledValue = 1;
    long loopCount = 0;

    LED_OUTPUT = ledValue;

    while (1) {

        if (loopCount > LOOP_DELAY) {

            loopCount = 0;
            ledValue = 1 - ledValue;

            LED_OUTPUT = ledValue;
        }

        loopCount++;
    }
}
