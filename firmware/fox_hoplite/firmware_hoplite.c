#include "io.h"
#include "print.h"
#include "network.h"

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

    LED_OUTPUT = 1;
}
