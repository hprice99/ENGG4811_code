#include "fox.h"
#include "print.h"

int foxStages;
int xOffset;
int yOffset;

int resultXCoord;
int resultYCoord;

long my_A[MATRIX_SIZE * MATRIX_SIZE];

long stage_A[MATRIX_SIZE * MATRIX_SIZE];
long stage_B[MATRIX_SIZE * MATRIX_SIZE];

long result_C[MATRIX_SIZE * MATRIX_SIZE];

int aElementsReceived;
int bElementsReceived;

enum FoxError send_A(int my_x_coord, int my_y_coord, int fox_rows) {

    enum NetworkError networkError = NETWORK_ERROR;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = A_type;
    packet.multicastGroup = 1;
    packet.destY = my_y_coord;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x;
            packet.matrixY = y;
            packet.matrixElement = my_A[index];

            #ifdef DEBUG_PRINT
            print_char('s');
            #endif

            // Loop through each destination and send
            for (int destX = 0; destX < fox_rows; destX++) {

                packet.destX = destX;

                networkError = send_message(packet);

                if (networkError == NETWORK_ERROR) {

                    print_string("send_A network error\n");

                    return FOX_NETWORK_ERROR;
                }
            }

            #ifdef DEBUG_PRINT
            print_matrix_packet("end_A", packet);
            #endif
        }
    }

    return FOX_SUCCESS;
}

enum FoxError send_B(int my_x_coord, int my_y_coord, int fox_cols) {

    enum NetworkError networkError = NETWORK_ERROR;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = B_type;
    packet.multicastGroup = 0;
    packet.destX = my_x_coord;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x;
            packet.matrixY = y;
            packet.matrixElement = stage_B[index];

            #ifdef DEBUG_PRINT
            print_char('s');
            #endif

            if (my_y_coord == 0) {

                packet.destY = fox_cols - 1;
            } else {

                packet.destY = my_y_coord - 1;
            }

            networkError = send_message(packet);

            #ifdef DEBUG_PRINT
            print_matrix_packet("end_B", packet);
            #endif

            if (networkError == NETWORK_ERROR) {

                print_string("send_B network error\n");

                return FOX_NETWORK_ERROR;
            }
        }
    }

    return FOX_SUCCESS;
}

enum FoxError assign_element(struct MatrixPacket packet) {

    // int index = packet.matrixY * MATRIX_SIZE + packet.matrixX;
    int index = COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

    #ifdef DEBUG_PRINT
    print_string("assign_element");
    print_string(", x = ");
    print_hex(packet.matrixX, 1);
    print_string(", y = ");
    print_hex(packet.matrixY, 1);

    print_string(", assign_element index = ");
    print_hex(index, 1);
    print_string(", element = ");
    print_hex(packet.matrixElement, 1);
    #endif

    if (packet.matrixType == A_type) {

        stage_A[index] = packet.matrixElement;
        aElementsReceived++;

        #ifdef DEBUG_PRINT
        print_string(", type = A");
        print_string("\n");

        print_string("aElementsReceived = ");
        print_hex(aElementsReceived, 3);
        print_string("\n");
        #endif
    } else if (packet.matrixType == B_type) {

        stage_B[index] = packet.matrixElement;
        bElementsReceived++;

        #ifdef DEBUG_PRINT
        print_string(", type = B");
        print_string("\n");

        print_string("bElementsReceived = ");
        print_hex(bElementsReceived, 3);
        print_string("\n");
        #endif
    }

    return FOX_SUCCESS;
}

enum FoxError receive_matrix(enum MatrixType matrixType) {

    enum NetworkError networkError;
    struct MatrixPacket packet;

    long receiveLoopsLevel1 = 0;
    long receiveLoopsLevel2 = 0;

    while ((matrixType == A_type && aElementsReceived < MATRIX_ELEMENTS) || 
            (matrixType == B_type && bElementsReceived < MATRIX_ELEMENTS)) {

        // Reset networkError before trying to receive each packet
        networkError = NETWORK_ERROR;

        receiveLoopsLevel1 = 0;
        receiveLoopsLevel2 = 0;

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

        #ifdef DEBUG_PRINT
        print_matrix_packet("receive_matrix", packet);
        #endif

        if (networkError == NETWORK_ERROR || 
                networkError == NETWORK_MESSAGE_IN_UNAVAILABLE) {

            print_string("receive_matrix network timeout error\n");

            return FOX_NETWORK_TIMEOUT_ERROR;
        }

        assign_element(packet);
    }

    // Reset the number of elements received in the desired matrix
    if (matrixType == A_type) {

        aElementsReceived = 0;
    } else if (matrixType == B_type) {

        bElementsReceived = 0;
    }

    return FOX_SUCCESS;
}

bool is_broadcast_stage(int my_x_coord, int my_y_coord, int stage) {

    int broadcastXCoord = stage + my_y_coord;

    // Modulo operation
    if (broadcastXCoord >= foxStages) {

        broadcastXCoord = broadcastXCoord - foxStages;
    }

    return (my_x_coord == broadcastXCoord);
}

enum FoxError fox_algorithm(int my_x_coord, int my_y_coord) {

    aElementsReceived = 0;
    bElementsReceived = 0;

    for (int stage = 0; stage < foxStages; stage++) {

        // Broadcast A
        if (is_broadcast_stage(my_x_coord, my_y_coord, stage)) {

            send_A(my_x_coord, my_y_coord, foxStages);
        }

        receive_matrix(A_type);

        // Multiply matrices
        multiply_matrices(stage_A, stage_B, result_C);

        // Don't need to send B matrix after last multiplication operation
        if (stage != foxStages - 1) {

            // Rotate B matrix up
            send_B(my_x_coord, my_y_coord, foxStages);

            // Receive new B matrix
            receive_matrix(B_type);
        }
    }
}
