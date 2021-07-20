#include "network.h"

int send_message(struct MatrixPacket packet) {

    if (MESSAGE_OUT_READY_INPUT == 0) {

        return NETWORK_ERROR;
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

    // Assert packet complete
    PACKET_COMPLETE_OUTPUT = 1;

    return NETWORK_SUCCESS;
}

int receive_message(struct MatrixPacket* packet) {

    // if (MESSAGE_IN_AVAILABLE_INPUT == 0 || MESSAGE_VALID_INPUT == 0) {
    if (MESSAGE_IN_AVAILABLE_INPUT == 0) { 
        
        return NETWORK_ERROR;
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

    return NETWORK_SUCCESS;
}