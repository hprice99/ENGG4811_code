#include "network.h"

int send_message(int dest_x, int dest_y, long message) {

    if (MESSAGE_OUT_READY_INPUT == 0) {

        return NETWORK_ERROR;
    }

    // Set packet fields
    X_COORD_OUTPUT = dest_x;
    Y_COORD_OUTPUT = dest_y;
    MESSAGE_OUTPUT = message;

    // Assert packet complete
    PACKET_COMPLETE_OUTPUT = 1;

    return NETWORK_SUCCESS;
}

int receive_message(long* message) {

    if (MESSAGE_IN_AVAILABLE_INPUT == 0) { 
        
        return NETWORK_ERROR;
    }

    *message = MESSAGE_INPUT;

    return NETWORK_SUCCESS;
}