#include "matrix.h"
#include "print.h"

void print_matrix(long* matrix, int rows, int cols) {

    char digit[7];

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            // TODO Determine number of digits
            // print_hex(*((matrix + row * rows) + col), 4);
        }
        print_string(" ; \n");
    }
}

void output_digit(long digit) {

    MATRIX_OUTPUT = digit;
}

void output_matrix(char* label, long* matrix, int rows, int cols) {

    print_string(label);
    print_string(" = [ \n");

    for (long row = 0; row < rows; row++) {
        for (long col = 0; col < cols; col++) {
            
            output_digit(*((matrix + row * rows) + col));
        }
        MATRIX_ROW_END = 1;
    }

    MATRIX_END = 1;

    print_string("] \n\n");
}

// TODO Make matrix_size a parameter
void multiply_matrices(long* A, long* B, long* C) {

    for (long i = 0; i < MATRIX_SIZE; i++) {
        for (long j = 0; j < MATRIX_SIZE; j++) {

            int cIndex = i * MATRIX_SIZE + j;

            for (long k = 0; k < MATRIX_SIZE; k++) {
                int aIndex = i * MATRIX_SIZE + k;
                int bIndex = k * MATRIX_SIZE + j;

                C[cIndex] = C[cIndex] + A[aIndex] * B[bIndex];
            }
        }

        #ifdef MATRIX_POSITION_OUT_ENABLED
        MATRIX_POSITION = i;

        print_string(" Row done\n");
        #endif
    }
}
