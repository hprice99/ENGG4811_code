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

#ifdef TB_PRINT
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
#endif

void create_my_A(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        print_string("Loading A from file\n");

        int aElementsReceived = 0;
        struct MatrixPacket packet;
        enum FoxError foxError = FOX_NETWORK_ERROR;

        while (aElementsReceived < MATRIX_ELEMENTS) {

            foxError = receive_fox_packet(&packet);

            if (packet.matrixType != A_type) {

                print_string("Expected to receive A matrix\n");
                return;
            }

            int index = COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

            my_A[index] = packet.matrixElement;
            
            aElementsReceived++;
        }
    } else {

        for (long x = 0; x < MATRIX_SIZE; x++) {
            for (long y = 0; y < MATRIX_SIZE; y++) {

                int index = COORDINATE_TO_INDEX(x, y);

                my_A[index] = my_node_number + 1;
                // my_A[index] = my_node_number + x + y + 1;
            }
        }
    }
}

void create_initial_stage_B(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        print_string("Loading B from file\n");

        int bElementsReceived = 0;
        struct MatrixPacket packet;
        enum FoxError foxError = FOX_NETWORK_ERROR;

        while (bElementsReceived < MATRIX_ELEMENTS) {

            foxError = receive_fox_packet(&packet);

            if (packet.matrixType != B_type) {

                print_string("Expected to receive A matrix\n");
                return;
            }

            int index = COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

            stage_B[index] = packet.matrixElement;
            
            bElementsReceived++;
        }
    } else {

        for (long x = 0; x < MATRIX_SIZE; x++) {
            for (long y = 0; y < MATRIX_SIZE; y++) {

                int index = COORDINATE_TO_INDEX(x, y);

                stage_B[index] = my_node_number + 1;
                // stage_B[index] = 2 * my_node_number + 4;
                // stage_B[index] = 2 * my_node_number + x + y + 4;
            }
        }
    }
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

    foxStages = FOX_NETWORK_STAGES_INPUT;

    #ifdef TB_PRINT
    print_string("Node coordinates (");
    print_hex(my_x_coord, 1);
    print_string(", ");
    print_hex(my_y_coord, 1);
    print_string("), node number = ");
    print_hex(my_node_number, 1);

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
    print_char('\n');
    print_char('\n');
    #endif

    int ledValue = 1;
    long loopCount = 0;

    create_my_A();
    #ifdef TB_PRINT
    tb_output_matrix("A", my_A, MATRIX_SIZE, MATRIX_SIZE);
    print_char('\n');
    #endif

    create_initial_stage_B();
    #ifdef TB_PRINT
    tb_output_matrix("B", stage_B, MATRIX_SIZE, MATRIX_SIZE);
    print_char('\n');
    #endif

    initialise_C();

    #ifdef RESULT
    print_string("Result node ");
    print_dec(my_node_number);
    print_char('\n');
    print_char('\n');
    #endif

    #ifdef TB_PRINT
    print_string("TB_PRINT defined\n");
    #endif

    fox_algorithm(my_x_coord, my_y_coord);

    #ifdef TB_PRINT
    tb_output_matrix("Matrix multiplication complete. C", result_C, 
            MATRIX_SIZE, MATRIX_SIZE);
    #endif

    
    #ifdef RESULT
    // Receive results and print to UART
    assign_my_C();
    receive_result();
    print_C();
    #else
    // Send the results to the result node
    send_C(my_x_coord, my_y_coord);
    #endif

    LED_OUTPUT = ledValue;
    int ledToggles = 0;

    #ifdef RESULT
    print_string("\nLED ");

    if (ledValue == 0) {
        
        print_string("off, ");
    } else if (ledValue == 1) {

        print_string("on,  ");
    }

    print_string("ledToggles = ");
    print_dec(ledToggles);
    print_char('\n');
    #endif

    while (1) {

        if (loopCount > LOOP_DELAY) {

            loopCount = 0;
            ledValue = 1 - ledValue;
            ledToggles++;

            LED_OUTPUT = ledValue;

            #ifdef RESULT
            print_string("LED ");

            if (ledValue == 0) {
                
                print_string("off, ");
            } else if (ledValue == 1) {

                print_string("on,  ");
            }

            print_string("ledToggles = ");
            print_dec(ledToggles);
            print_char('\n');
            #endif

        }

        loopCount++;
    }
}
