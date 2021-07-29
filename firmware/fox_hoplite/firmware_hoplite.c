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

#ifdef CHECK_C
#define RESULT_FLASH    10000000

// Expected results
long expected_C[][MATRIX_SIZE * MATRIX_SIZE] = {
    {20}, 
    {26}, 
    {44}, 
    {58}
};
#endif

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

#ifdef CHECK_C
bool check_C(void) {

    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            if (expected_C[my_node_number][index] != result_C[index]) {

                return false;
            }
        }
    }

    long loopCount = 0;
    int resultFlashes = 0;

    int ledValue = 0;
    LED_OUTPUT = ledValue;

    // Flash LEDs quickly to show result
    while (resultFlashes < 100) {

        if (loopCount > RESULT_FLASH) {

            loopCount = 0;
            ledValue = 1 - ledValue;

            LED_OUTPUT = ledValue;
        }

        loopCount++;

        resultFlashes++;
    }

    return true;
}
#endif

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

    #ifdef CHECK_C
    bool cCorrect = check_C();
    if (cCorrect) {

        print_string("C correct\n");
    } else {

        print_string("C incorrect\n");
    }
    #else
    bool cCorrect = true;
    #endif

    LED_OUTPUT = ledValue;

    if (cCorrect) {
        
        while (1) {

            if (loopCount > LOOP_DELAY) {

                loopCount = 0;
                ledValue = 1 - ledValue;

                LED_OUTPUT = ledValue;
            }

            loopCount++;
        }
    }
}
