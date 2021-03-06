#include "matrix.h"
#include "print.h"

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
    }
}
