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

#ifdef RESULT
long total_C[TOTAL_MATRIX_SIZE * TOTAL_MATRIX_SIZE];
int cElementsReceived;
#endif

int aElementsReceived;
int bElementsReceived;

enum FoxError receive_fox_packet(struct MatrixPacket* packet) {

    enum NetworkError networkError = NETWORK_ERROR;

    int receiveLoopsLevel1 = 0;
    int receiveLoopsLevel2 = 0;

    while (receiveLoopsLevel1 < FOX_NETWORK_WAIT && 
            networkError != NETWORK_SUCCESS) {
        
        while (receiveLoopsLevel2 < FOX_NETWORK_WAIT && 
                networkError != NETWORK_SUCCESS) {

            networkError = receive_message(packet);
            receiveLoopsLevel2++;
        }

        receiveLoopsLevel2 = 0;

        receiveLoopsLevel1++;
    }
    
    if (receiveLoopsLevel1 == FOX_NETWORK_WAIT) {

        return FOX_NETWORK_TIMEOUT_ERROR;
    }

    if (networkError == NETWORK_ERROR || 
            networkError == NETWORK_MESSAGE_IN_UNAVAILABLE) {

        print_string("receive_fox_packet network timeout error\n");

        return FOX_NETWORK_TIMEOUT_ERROR;
    }

    return FOX_SUCCESS;
}

enum FoxError send_ready(int my_x_coord, int my_y_coord, 
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
    print_matrix_packet("Sent ready", packet);
    #endif

    if (networkError == NETWORK_ERROR) {

        print_string("send_ready network error\n");

        return FOX_NETWORK_ERROR;
    }

    return FOX_SUCCESS;
}

bool is_a_broadcast_ready(int my_x_coord, int my_y_coord, int fox_cols) {

    int nodesReady = 0;
    int broadcastDestinations = fox_cols - 1;

    // Receive ready packets
    struct MatrixPacket packet;

    while (nodesReady < broadcastDestinations) {

        receive_fox_packet(&packet);

        #ifdef DEBUG_PRINT
        print_matrix_packet("a_broadcast_ready", packet);
        #endif

        // Check if the packet is broadcast
        if (packet.doneFlag == 1 && packet.matrixType == A_type) {

            nodesReady++;
        }
    }

    return true;
}

enum FoxError send_A(int my_x_coord, int my_y_coord) {

    enum NetworkError networkError = NETWORK_ERROR;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = A_type;
    packet.multicastGroup = 1;
    packet.destY = my_y_coord;
    packet.destX = my_x_coord;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = FOX_COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x;
            packet.matrixY = y;
            packet.matrixElement = my_A[index];

            #ifdef DEBUG_PRINT
            print_char('s');
            #endif

            // Send message over multicast
            do {
                networkError = send_message(packet);
            } while (networkError != NETWORK_SUCCESS);

            if (networkError == NETWORK_ERROR) {

                print_string("send_A network error\n");

                return FOX_NETWORK_ERROR;
            }

            #ifdef DEBUG_PRINT
            print_matrix_packet("end_A", packet);
            #endif
        }
    }

    return FOX_SUCCESS;
}

bool is_b_send_ready(int my_x_coord, int my_y_coord, int fox_rows) {

    int nodesReady = 0;
    int bDestinations = 1;

    // Receive ready packets
    struct MatrixPacket packet;

    while (nodesReady < bDestinations) {

        receive_fox_packet(&packet);

        #ifdef DEBUG_PRINT
        print_matrix_packet("b_send_ready", packet);
        #endif

        // Check if the packet is broadcast
        if (packet.doneFlag == 1 && packet.matrixType == B_type) {

            nodesReady++;
        }
    }

    return true;
}

enum FoxError send_B(int my_x_coord, int my_y_coord, int fox_rows) {

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

            int index = FOX_COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x;
            packet.matrixY = y;
            packet.matrixElement = stage_B[index];

            #ifdef DEBUG_PRINT
            print_char('s');
            #endif

            if (my_y_coord == 0) {

                packet.destY = fox_rows - 1;
            } else {

                packet.destY = my_y_coord - 1;
            }

            do {
                networkError = send_message(packet);
            } while (networkError != NETWORK_SUCCESS);

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

enum FoxError send_C(int my_x_coord, int my_y_coord) {

    enum NetworkError networkError = NETWORK_ERROR;

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = true;
    packet.matrixType = A_type;
    packet.multicastGroup = 0;
    packet.destX = resultXCoord;
    packet.destY = resultYCoord;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = FOX_COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x + xOffset;
            packet.matrixY = y + yOffset;
            packet.matrixElement = result_C[index];

            #ifdef DEBUG_PRINT
            print_char('s');
            #endif

            do {
                networkError = send_message(packet);
            } while (networkError != NETWORK_SUCCESS);

            #ifdef DEBUG_PRINT
            print_matrix_packet("end_C", packet);
            #endif

            if (networkError == NETWORK_ERROR) {

                print_string("send_C network error\n");

                return FOX_NETWORK_ERROR;
            }
        }
    }

    return FOX_SUCCESS;
}

enum FoxError assign_element(struct MatrixPacket packet) {

    // int index = packet.matrixY * MATRIX_SIZE + packet.matrixX;
    int index = FOX_COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

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

        print_string("assign_element - aElementsReceived = ");
        print_hex(aElementsReceived, 3);
        print_string("\n");
        #endif
    } else if (packet.matrixType == B_type) {

        stage_B[index] = packet.matrixElement;
        bElementsReceived++;

        #ifdef DEBUG_PRINT
        print_string(", type = B");
        print_string("\n");

        print_string("assign_element - bElementsReceived = ");
        print_hex(bElementsReceived, 3);
        print_string("\n");
        #endif
    }

    return FOX_SUCCESS;
}

enum FoxError assign_my_A(void) {

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = false;
    packet.matrixType = A_type;
    packet.multicastGroup = 1;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = FOX_COORDINATE_TO_INDEX(x, y);

            packet.matrixX = x;
            packet.matrixY = y;
            packet.matrixElement = my_A[index];

            assign_element(packet);
        }
    }

    // Reset the number of A elements received so that the next stage works
    aElementsReceived = 0;
}

enum FoxError receive_matrix(enum MatrixType matrixType) {

    struct MatrixPacket packet;

    while ((matrixType == A_type && aElementsReceived < MATRIX_ELEMENTS) || 
            (matrixType == B_type && bElementsReceived < MATRIX_ELEMENTS)) {

        receive_fox_packet(&packet);

        #ifdef DEBUG_PRINT
        print_matrix_packet("receive_matrix", packet);
        #endif

        assign_element(packet);

        #ifdef DEBUG_PRINT
        if (matrixType == A_type) {

            print_string("receive_matrix - aElementsReceived = ");
            print_hex(aElementsReceived, 3);
            print_string("\n");
        } else if (matrixType == B_type) {

            print_string("receive_matrix - bElementsReceived = ");
            print_hex(bElementsReceived, 3);
            print_string("\n");
        }
        #endif
    }

    // Reset the number of elements received in the desired matrix
    if (matrixType == A_type) {

        aElementsReceived = 0;
    } else if (matrixType == B_type) {

        bElementsReceived = 0;
    }

    return FOX_SUCCESS;
}

#ifdef RESULT
enum FoxError assign_my_C(void) {

    #ifdef DEBUG_PRINT
    print_string("assign_my_c\n");
    #endif

    struct MatrixPacket packet;

    packet.doneFlag = false;
    packet.resultFlag = true;
    packet.matrixType = A_type;
    packet.multicastGroup = 0;

    // Loop through matrix elements
    for (long x = 0; x < MATRIX_SIZE; x++) {
        for (long y = 0; y < MATRIX_SIZE; y++) {

            int index = FOX_COORDINATE_TO_INDEX(x, y);

            int cX = x + xOffset;
            int cY = y + yOffset;

            packet.matrixX = cX;
            packet.matrixY = cY;
            packet.matrixElement = result_C[index];

            assign_result(packet);
        }
    }
}

enum FoxError receive_result(void) {

    struct MatrixPacket packet;

    while (cElementsReceived < TOTAL_MATRIX_ELEMENTS) {

        receive_fox_packet(&packet);

        #ifdef DEBUG_PRINT
        print_matrix_packet("receive_matrix", packet);
        #endif

        assign_result(packet);
    }

    return FOX_SUCCESS;
}

enum FoxError assign_result(struct MatrixPacket packet) {

    int index = RESULT_COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

    if (packet.resultFlag != 1) {

        print_string("Did not receive C matrix\n");
        return FOX_ASSIGNMENT_ERROR;
    }

    #ifdef DEBUG_PRINT
    print_matrix_packet("assign_result", packet);

    print_string("assign_result");
    print_string(", x = ");
    print_hex(packet.matrixX, 1);
    print_string(", y = ");
    print_hex(packet.matrixY, 1);

    print_string(", assign_result index = ");
    print_dec(index);
    print_string(", element = ");
    print_dec(packet.matrixElement);
    #endif

    total_C[index] = packet.matrixElement;
    cElementsReceived++;

    #ifdef DEBUG_PRINT
    print_string(", type = C");
    print_string("\n");

    print_string("cElementsReceived = ");
    print_dec(cElementsReceived);
    print_string("\n");
    #endif

    return FOX_SUCCESS;
}
#endif

int get_broadcast_stage_node(int my_x_coord, int my_y_coord, int stage) {

    int broadcastXCoord = stage + my_y_coord;

    // Modulo operation
    if (broadcastXCoord >= foxStages) {

        broadcastXCoord = broadcastXCoord - foxStages;
    }

    return broadcastXCoord;
}

enum FoxError fox_algorithm(int my_x_coord, int my_y_coord) {

    aElementsReceived = 0;
    bElementsReceived = 0;
    
    #ifdef RESULT
    cElementsReceived = 0;
    #endif

    int broadcastNodeX = -1;

    int receiveBFrom;

    if (my_y_coord == foxStages - 1) {

        receiveBFrom = 0;
    } else {

        receiveBFrom = my_y_coord + 1;
    }

    for (int stage = 0; stage < foxStages; stage++) {

        broadcastNodeX = 
                get_broadcast_stage_node(my_x_coord, my_y_coord, stage);

        // Broadcast A
        if (my_x_coord == broadcastNodeX) {

            // Wait for all receivers to be ready
            while (!is_a_broadcast_ready(my_x_coord, my_y_coord, foxStages)) {

                __asm__("nop");
            }

            #ifdef TB_PRINT
            print_string("broadcast_A ready\n");
            #endif

            send_A(my_x_coord, my_y_coord);
        } else {

            send_ready(my_x_coord, my_y_coord, A_type, broadcastNodeX, 
                    my_y_coord);
        }

        receive_matrix(A_type);

        // Multiply matrices
        multiply_matrices(stage_A, stage_B, result_C);

        // Don't need to send B matrix after last multiplication operation
        if (stage != foxStages - 1) {

            send_ready(my_x_coord, my_y_coord, B_type, my_x_coord, 
                    receiveBFrom);
            
            // Wait for receiver to be ready
            while (!is_b_send_ready(my_x_coord, my_y_coord, foxStages)) {

                __asm__("nop");
            }

            #ifdef TB_PRINT
            print_string("send_B ready\n");
            #endif

            // Rotate B matrix up
            send_B(my_x_coord, my_y_coord, foxStages);

            // Receive new B matrix
            receive_matrix(B_type);
        }
    }
}
