#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "matrix.h"

#define LOOP_DELAY      40000000

#define MAX_ENTRY 10

long A[MATRIX_SIZE * MATRIX_SIZE];
long B[MATRIX_SIZE * MATRIX_SIZE];
long C[MATRIX_SIZE * MATRIX_SIZE];

enum MatrixType {
    A_type = 0, 
    B_type = 1
};

struct MatrixPacket {
    enum MatrixType matrixType;
    int matrixX;
    int matrixY;
    long matrixElement;
};

void print_matrix(char* matrixName, long* matrix, int rows, int cols) {

    print_string(matrixName);
    print_string(" = [");
    for (long y = 0; y < rows; y++) {
        for (long x = 0; x < cols; x++) {

            int index = COORDINATE_TO_INDEX(x, y);

            print_dec(matrix[index]);

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

struct MatrixPacket readMatrixPacket(void) {

    struct MatrixPacket packet;

    packet.matrixType = MATRIX_INIT_TYPE_INPUT;
    packet.matrixX = MATRIX_INIT_X_COORD_INPUT;
    packet.matrixY = MATRIX_INIT_Y_COORD_INPUT;
    packet.matrixElement = MATRIX_INIT_ELEMENT_INPUT;

    MATRIX_INIT_READ_OUTPUT = 1;

    return packet;
}

void createA(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        print_string("Loading A from file\n");

        int aElementsReceived = 0;
        struct MatrixPacket packet;

        while (aElementsReceived < MATRIX_ELEMENTS) {

            packet = readMatrixPacket();

            if (packet.matrixType != A_type) {

                print_string("Expected to receive A matrix\n");
                return;
            }

            int index = COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

            A[index] = packet.matrixElement;
            
            aElementsReceived++;

            #ifdef DEBUG_PRINT
            print_string("A[");
            print_dec(packet.matrixX);
            print_string(", ");
            print_dec(packet.matrixY);
            print_string("] = ");
            print_dec(packet.matrixElement);
            print_char('\n');

            print_dec(aElementsReceived);
            print_string(" elements of A received\n");
            #endif
        }
    } else {

        for (long x = 0; x < MATRIX_SIZE; x++) {
            for (long y = 0; y < MATRIX_SIZE; y++) {

                int index = COORDINATE_TO_INDEX(x, y);

                A[index] = 1;
            }
        }
    }
}

void createB(void) {

    if (MATRIX_INIT_FROM_FILE_INPUT) {

        print_string("Loading B from file\n");

        int bElementsReceived = 0;
        struct MatrixPacket packet;

        while (bElementsReceived < MATRIX_ELEMENTS) {

            packet = readMatrixPacket();

            if (packet.matrixType != B_type) {

                print_string("Expected to receive B matrix\n");
                return;
            }

            int index = COORDINATE_TO_INDEX(packet.matrixX, packet.matrixY);

            B[index] = packet.matrixElement;
            
            bElementsReceived++;

            #ifdef DEBUG_PRINT
            print_string("B[");
            print_dec(packet.matrixX);
            print_string(", ");
            print_dec(packet.matrixY);
            print_string("] = ");
            print_dec(packet.matrixElement);
            print_char('\n');

            print_dec(bElementsReceived);
            print_string(" elements of B received\n");
            #endif
        }
    } else {

        for (long x = 0; x < MATRIX_SIZE; x++) {
            for (long y = 0; y < MATRIX_SIZE; y++) {

                int index = COORDINATE_TO_INDEX(x, y);

                B[index] = 1;
            }
        }
    }
}

void createC(void) {

    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            C[index] = 0;
        }
    }
}

void main(void) {

    createA();
    createB();
    createC();

    multiply_matrices(A, B, C);

    MATRIX_MULTIPLY_DONE_OUTPUT = 1;
    print_matrix("C", C, MATRIX_SIZE, MATRIX_SIZE);
}
