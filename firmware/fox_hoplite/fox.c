#include "fox.h"
#include "print.h"

int foxStages;
int xOffset;
int yOffset;

long my_A[MATRIX_SIZE * MATRIX_SIZE];

long stage_A[MATRIX_SIZE * MATRIX_SIZE];
long stage_B[MATRIX_SIZE * MATRIX_SIZE];

long result_C[MATRIX_SIZE * MATRIX_SIZE];

enum FoxError send_A(int my_x_coord, int my_y_coord, int fox_rows) {

    enum NetworkError networkError;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = A_type;
    packet.multicastGroup = 1;
    packet.destY = my_y_coord;

    // Loop through matrix elements
    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            packet.matrixX = xOffset + col;
            packet.matrixY = yOffset + row;
            packet.matrixElement = my_A[index];

            /*
            print_string("send_A");
            print_string(", x = ");
            print_hex(col, 1);
            print_string(", xOffset = ");
            print_hex(xOffset, 1);
            print_string(", matrixX = ");
            print_hex(packet.matrixX, 1);
            print_string(", y = ");
            print_hex(row, 1);
            print_string(", yOffset = ");
            print_hex(yOffset, 1);
            print_string(", matrixY = ");
            print_hex(packet.matrixY, 1);
            print_string(", element = ");
            print_hex(packet.matrixElement, 1);
            print_string("\n");
            */

            // Loop through each destination and send
            for (int destX = 0; destX < fox_rows; destX++) {

                packet.destX = destX;

                networkError = send_message(packet);

                if (networkError == NETWORK_ERROR) {

                    print_string("send_A network error\n");

                    return FOX_NETWORK_ERROR;
                }
            }

            print_string("send_A ");
            print_matrix_packet(packet);
        }
    }

    return FOX_SUCCESS;
}

enum FoxError send_B(int my_x_coord, int my_y_coord, int fox_cols) {

    enum NetworkError networkError;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = B_type;
    packet.multicastGroup = 0;
    packet.destX = my_x_coord;

    // Loop through matrix elements
    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            packet.matrixX = xOffset + col;
            packet.matrixY = yOffset + row;
            packet.matrixElement = stage_B[index];

            /*
            print_string("send_B");
            print_string(", x = ");
            print_hex(col, 1);
            print_string(", xOffset = ");
            print_hex(xOffset, 1);
            print_string(", matrixX = ");
            print_hex(packet.matrixX, 1);
            print_string(", y = ");
            print_hex(row, 1);
            print_string(", yOffset = ");
            print_hex(yOffset, 1);
            print_string(", matrixY = ");
            print_hex(packet.matrixY, 1);
            print_string(", element = ");
            print_hex(packet.matrixElement, 1);
            print_string("\n");
            */

            if (my_y_coord == 0) {

                packet.destY = fox_cols - 1;
            } else {

                packet.destY = my_y_coord - 1;
            }

            networkError = send_message(packet);

            print_string("send_B packet.destY = ");
            print_hex(packet.destY, 1);
            print_string("\n");

            if (networkError == NETWORK_ERROR) {

                print_string("send_B network error\n");

                return FOX_NETWORK_ERROR;
            }

            print_string("send_B ");
            print_matrix_packet(packet);
        }
    }

    return FOX_SUCCESS;
}

enum FoxError assign_element(enum MatrixType matrixType, int x, int y, 
        int element) {

    int shiftedX = x - xOffset;
    int shiftedY = y - yOffset;

    int index = shiftedY * MATRIX_SIZE + shiftedX;

    /*
    print_string("assign_element");
    print_string(", x = ");
    print_hex(x, 1);
    print_string(", xOffset = ");
    print_hex(xOffset, 1);
    print_string(", shiftedX = ");
    print_hex(shiftedX, 1);
    print_string(", y = ");
    print_hex(y, 1);
    print_string(", yOffset = ");
    print_hex(yOffset, 1);
    print_string(", shiftedY = ");
    print_hex(shiftedY, 1);

    print_string(", assign_element index = ");
    print_hex(index, 1);
    print_string(", element = ");
    print_hex(element, 1);
    */

    if (matrixType == A_type) {

        stage_A[index] = element;

        // print_string(", type = A");
    } else if (matrixType == B_type) {

        stage_B[index] = element;
        // print_string(", type = B");
    }

    // print_string("\n");

    return FOX_SUCCESS;
}

enum FoxError receive_matrix(enum MatrixType matrixType) {

    int elementsReceived = 0;
    enum NetworkError networkError;
    struct MatrixPacket packet;

    long receiveLoopsLevel1 = 0;
    long receiveLoopsLevel2 = 0;

    while (elementsReceived < MATRIX_SIZE) {

        while (receiveLoopsLevel1 < FOX_NETWORK_WAIT && 
                networkError != NETWORK_SUCCESS) {
            
            while (receiveLoopsLevel2 < FOX_NETWORK_WAIT && 
                    networkError != NETWORK_SUCCESS) {

                networkError = receive_message(&packet);
                receiveLoopsLevel2++;
            }

            receiveLoopsLevel2 = 0;

            receiveLoopsLevel1++;
        }
        receiveLoopsLevel1 = 0;

        if (networkError == NETWORK_ERROR || 
                networkError == NETWORK_MESSAGE_UNAVAILABLE) {

            print_string("receive_matrix network timeout error\n");

            return FOX_NETWORK_TIMEOUT_ERROR;
        }

        print_string("receive_matrix ");
        print_matrix_packet(packet);

        if (packet.matrixType != matrixType) {

            print_string("receive_matrix assignment error\n");

            return FOX_ASSIGNMENT_ERROR;
        }

        assign_element(packet.matrixType, packet.matrixX, packet.matrixY, 
                packet.matrixElement);

        elementsReceived++;
    }
}

bool is_broadcast_stage(int my_x_coord, int my_y_coord, int stage) {

    int broadcastXCoord = stage + my_y_coord;

    // Modulo operation
    if (broadcastXCoord >= foxStages) {

        broadcastXCoord = broadcastXCoord - foxStages;
    }

    return (my_x_coord == broadcastXCoord);
}

enum FoxError fox_matrix_multiply(void) {

    for (long i = 0; i < MATRIX_SIZE; i++) {
        for (long j = 0; j < MATRIX_SIZE; j++) {

            int cIndex = i * MATRIX_SIZE + j;

            for (long k = 0; k < MATRIX_SIZE; k++) {
                int aIndex = i * MATRIX_SIZE + k;
                int bIndex = k * MATRIX_SIZE + j;

                result_C[cIndex] = result_C[cIndex] + 
                        stage_A[aIndex] * stage_B[bIndex];
            }
        }
    }

    return FOX_SUCCESS;
}

enum FoxError fox_algorithm(int my_x_coord, int my_y_coord) {

    for (int stage = 0; stage < foxStages; stage++) {

        // Broadcast A or receive A
        if (is_broadcast_stage(my_x_coord, my_y_coord, stage)) {

            /*
            print_string("Stage ");
            print_hex(stage, 1);
            print_string(", ");
            */

            send_A(my_x_coord, my_y_coord, foxStages);
        }

        /*
        print_string("Stage ");
        print_hex(stage, 1);
        print_string(", ");
        */

        /*
        // Wait until a message is available
        while (!NETWORK_MESSAGE_IS_AVAILABLE) {

            // __asm__("nop");
        }
        */

        print_string("A_type ");
        receive_matrix(A_type);

        // Multiply matrices
        multiply_matrices(stage_A, stage_B, result_C);


        if (stage != foxStages - 1) {

            // Rotate B matrix up
            send_B(my_x_coord, my_y_coord, foxStages);

            // Receive new B matrix
            receive_matrix(B_type);
        }
    }
}
