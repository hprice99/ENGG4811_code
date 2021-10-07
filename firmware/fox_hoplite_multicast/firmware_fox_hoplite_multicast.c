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

enum FoxError send_burst_ready(int my_x_coord, int my_y_coord, 
        enum MatrixType matrixType, int dest_x_coord, int dest_y_coord) {
    
    enum NetworkError networkError = NETWORK_ERROR;

    struct MatrixPacket packet;

    packet.doneFlag = true;
    packet.resultFlag = false;
    packet.matrixType = matrixType;
    packet.multicastGroup = 0;

    packet.destX = dest_x_coord;
    packet.destY = dest_y_coord;

    packet.matrixX = my_x_coord;
    packet.matrixY = my_y_coord;

    packet.matrixElement = 0;

    do {
        networkError = send_message(packet);
    } while (networkError != NETWORK_SUCCESS);

    #ifdef DEBUG_PRINT
    print_matrix_packet("Sent burst ready", packet);
    #endif

    if (networkError == NETWORK_ERROR) {

        print_string("send_burst_ready network error\n");

        return FOX_NETWORK_ERROR;
    }

    return FOX_SUCCESS;
}

void create_my_A(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        send_burst_ready(my_x_coord, my_y_coord, A_type, ROM_X_COORD_INPUT, 
                ROM_Y_COORD_INPUT);

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
            }
        }
    }
}

void create_initial_stage_B(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        send_burst_ready(my_x_coord, my_y_coord, B_type, ROM_X_COORD_INPUT, 
                ROM_Y_COORD_INPUT);

        int bElementsReceived = 0;
        struct MatrixPacket packet;
        enum FoxError foxError = FOX_NETWORK_ERROR;

        while (bElementsReceived < MATRIX_ELEMENTS) {

            foxError = receive_fox_packet(&packet);

            if (packet.matrixType != B_type) {

                print_string("Expected to receive B matrix\n");
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

    #ifdef TB_PRINT
    #ifdef RESULT
    print_string("Result node ");
    print_dec(my_node_number);
    print_char('\n');
    print_char('\n');
    #endif
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
    MATRIX_MULTIPLY_DONE_OUTPUT = 1;
    print_C();
    #else
    // Send the results to the result node
    send_C(my_x_coord, my_y_coord);
    #endif
}
