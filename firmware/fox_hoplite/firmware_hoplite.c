#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "network.h"

#include <stdbool.h>

#include "matrix.h"
#include "fox.h"

#define LOOP_DELAY 40000000

int my_x_coord;
int my_y_coord;
int my_node_number;

void tb_output_matrix(char* label, long* matrix, int rows, int cols) {

    print_string(label);
    print_string(" = [ ");

    for (long row = 0; row < rows; row++) {
        for (long col = 0; col < cols; col++) {
            
            output_digit(*((matrix + row * rows) + col));
        }
        MATRIX_ROW_END = 1;
    }

    MATRIX_END = 1;

    print_string("] \n");
}

void create_my_A(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            my_A[index] = my_node_number + 1;
        }
    }

    tb_output_matrix("A", my_A, MATRIX_SIZE, MATRIX_SIZE);
    print_string("\n");
}

void create_initial_stage_B(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            stage_B[index] = 2 * my_node_number + 4;
        }
    }

    tb_output_matrix("B", stage_B, MATRIX_SIZE, MATRIX_SIZE);
    print_string("\n");
}

void initialise_C(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            result_C[index] = 0;
        }
    }
}

void main() {

    // Read node coordinates from hardware and print
    my_x_coord = X_COORD_INPUT;
    my_y_coord = Y_COORD_INPUT;
    my_node_number = NODE_NUMBER_INPUT;
    xOffset = MATRIX_X_OFFSET_INPUT;
    yOffset = MATRIX_Y_OFFSET_INPUT;

    print_string("Node coordinates (");
    print_hex(my_x_coord, 1);
    print_string(", ");
    print_hex(my_y_coord, 1);
    print_string("), node number = ");
    print_hex(my_node_number, 1);

    foxStages = FOX_NETWORK_STAGES_INPUT;
    print_string(", Fox stages = ");
    print_hex(foxStages, 1);
    print_string(", xOffset = ");
    print_hex(xOffset, 3);
    print_string(", yOffset = ");
    print_hex(yOffset, 3);
    print_string("\n\n");

    int ledValue = 1;
    long loopCount = 0;

    create_my_A();
    create_initial_stage_B();
    initialise_C();

    fox_algorithm(my_x_coord, my_y_coord);

    // TODO Implement alternate result print
    tb_output_matrix("Matrix multiplication complete. C", result_C, 
            MATRIX_SIZE, MATRIX_SIZE);

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
