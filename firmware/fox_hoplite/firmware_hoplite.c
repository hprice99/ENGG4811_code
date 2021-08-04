#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "network.h"

#include <stdbool.h>

#include "matrix.h"
#include "fox.h"

#define LOOP_DELAY      40000000

int my_x_coord;
int my_y_coord;
int my_node_number;

void tb_output_matrix(char* label, long* matrix, int rows, int cols) {

    print_string(label);
    print_string(" = ");

    for (long row = 0; row < rows; row++) {
        MATRIX_END_ROW_OUTPUT = 1;
        for (long col = 0; col < cols; col++) {

            if (row == 0 && col == 0) {
                print_string("[");
            }
            
            output_digit(*((matrix + row * rows) + col));
        }
    }

    MATRIX_END_OUTPUT = 1;

    print_string("] \n");
}

void create_my_A(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            my_A[index] = my_node_number + 1;
            // my_A[index] = my_node_number + x + y + 1;
        }
    }

    tb_output_matrix("A", my_A, MATRIX_SIZE, MATRIX_SIZE);
    print_string("\n");
}

void create_initial_stage_B(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            stage_B[index] = my_node_number + 1;
            // stage_B[index] = 2 * my_node_number + 4;
            // stage_B[index] = 2 * my_node_number + x + y + 4;
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

#ifdef RESULT
void print_C(void) {

    print_string("C = [");
    for (long y = 0; y < TOTAL_MATRIX_SIZE; y++) {
        for (long x = 0; x < TOTAL_MATRIX_SIZE; x++) {

            int index = RESULT_COORDINATE_TO_INDEX(x, y);

            print_dec(total_C[index]);

            if (x < TOTAL_MATRIX_SIZE - 1) {
                print_string(", ");
            }
        }

        if (y < TOTAL_MATRIX_SIZE - 1) {

            print_string(";\n \t");
        }
    }

    print_string("]\n");
}
#endif

void main() {

    // Read node coordinates from hardware and print
    my_x_coord = X_COORD_INPUT;
    my_y_coord = Y_COORD_INPUT;
    my_node_number = NODE_NUMBER_INPUT;
    xOffset = MATRIX_X_OFFSET_INPUT;
    yOffset = MATRIX_Y_OFFSET_INPUT;

    resultXCoord = RESULT_X_COORD_INPUT;
    resultYCoord = RESULT_Y_COORD_INPUT;

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

    print_string(", matrix size = ");
    print_hex(MATRIX_SIZE, 1);
    print_string(", matrix elements = ");
    print_hex(MATRIX_ELEMENTS, 1);
    print_string(", resultXCoord = ");
    print_hex(resultXCoord, 1);
    print_string(", resultYCoord = ");
    print_hex(resultYCoord, 1);
    print_string("\n\n");

    int ledValue = 1;
    long loopCount = 0;

    create_my_A();
    create_initial_stage_B();
    initialise_C();

    #ifdef RESULT
    print_string("Result node ");
    print_dec(my_node_number);
    print_string("\n\n");
    #endif

    fox_algorithm(my_x_coord, my_y_coord);

    tb_output_matrix("Matrix multiplication complete. C", result_C, 
            MATRIX_SIZE, MATRIX_SIZE);

    #ifdef RESULT
    assign_my_C();
    receive_result();
    print_C();
    #else
    send_C(my_x_coord, my_y_coord);
    #endif

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
