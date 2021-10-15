#include "network.h"
#include "print.h"

struct MatrixPacket create_matrix_packet(int destX, int destY, 
        int multicastGroup, bool doneFlag, bool resultFlag, 
        enum MatrixType matrixType, int matrixX, int matrixY, 
        long matrixElement) {

    struct MatrixPacket packet;

    packet.destX = destX;
    packet.destY = destY;
    packet.multicastGroup = multicastGroup;
    packet.doneFlag = doneFlag;
    packet.resultFlag = resultFlag;
    packet.matrixType = matrixType;
    packet.matrixX = matrixX;
    packet.matrixY = matrixY;
    packet.matrixElement = matrixElement;

    return packet;
}

void print_matrix_packet(char* caller, struct MatrixPacket packet) {

    print_string(caller);

    print_string(" - matrix type = ");

    if (packet.resultFlag) {
        
        print_string("C");
    } else if (packet.matrixType == A_type) {

        print_string("A");
    } else if (packet.matrixType == B_type) {

        print_string("B");
    }

    print_string(", matrixX = ");
    print_hex(packet.matrixX, 1);
    print_string(", matrixY = ");
    print_hex(packet.matrixY, 1);
    print_string(", matrixElement = ");
    print_hex(packet.matrixElement, 2);

    print_string(", destination = (");
    print_hex(packet.destX, 1);
    print_string(", ");
    print_hex(packet.destY, 1);
    print_string(")");

    print_string("\n");
}

enum NetworkError send_message(struct MatrixPacket packet) {

    if (MESSAGE_OUT_READY_INPUT == 0) {

        return NETWORK_MESSAGE_OUT_UNAVAILABLE;
    }

    // Set packet fields
    X_COORD_OUTPUT = packet.destX;
    Y_COORD_OUTPUT = packet.destY;
    MULTICAST_GROUP_OUTPUT = packet.multicastGroup;
    DONE_FLAG_OUTPUT = packet.doneFlag;
    RESULT_FLAG_OUTPUT = packet.resultFlag;
    MATRIX_TYPE_OUTPUT = packet.matrixType;
    MATRIX_X_COORD_OUTPUT = packet.matrixX;
    MATRIX_Y_COORD_OUTPUT = packet.matrixY;
    MATRIX_ELEMENT_OUTPUT = packet.matrixElement;

    for (int i = 0; i < 12 * packet.destX + 8 * packet.destY; i++) {
        __asm__("nop");
    }

    // Assert packet complete
    PACKET_COMPLETE_OUTPUT = 1;

    return NETWORK_SUCCESS;
}

enum NetworkError receive_message(struct MatrixPacket* packet) {

    if (MESSAGE_IN_AVAILABLE_INPUT == 0) { 

        return NETWORK_MESSAGE_IN_UNAVAILABLE;
    } else if (NODE_NUMBER_INPUT == 7 || NODE_NUMBER_INPUT == 6) {
        print_string("receive_message\n");
    }

    packet->multicastGroup = MULTICAST_GROUP_INPUT;
    packet->doneFlag = DONE_FLAG_INPUT;
    packet->resultFlag = RESULT_FLAG_INPUT;
    packet->matrixType = MATRIX_TYPE_INPUT;
    packet->matrixX = MATRIX_X_COORD_INPUT;
    packet->matrixY = MATRIX_Y_COORD_INPUT;
    packet->matrixElement = MATRIX_ELEMENT_INPUT;

    // Move to the next message
    MESSAGE_READ_OUTPUT = 1;

    if (NODE_NUMBER_INPUT == 7 || NODE_NUMBER_INPUT == 6) {
        print_matrix_packet("receive_message", *packet);
    }

    return NETWORK_SUCCESS;
}