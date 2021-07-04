#include "firmware.h"
#include "matrix.h"
#include "print.h"

void print_matrix(long* matrix, int rows, int cols) {

    char digit[7];

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            print_string("itoa ");
            itoa(*((matrix + row * rows) + col), digit);

            print_string("Print ");
            print_string(digit);
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

void multiply_matrices(void) {

    // Create matrices
    long A[MATRIX_SIZE][MATRIX_SIZE];
    long B[MATRIX_SIZE][MATRIX_SIZE];
    long C[MATRIX_SIZE][MATRIX_SIZE];

    // Create random matrices
    /*
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            A[row][col] = myrand();
            B[row][col] = myrand();
            C[row][col] = 0;
        }
    }
    */

    // Create fixed matrices
    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {
            if (row < 50) {
                A[row][col] = row + 1;
            } else {
                A[row][col] = row - 50;
            }
            
            if (col < 50) {
                B[row][col] = col + 1;
            } else {
                B[row][col] = col - 50;
            }
            
            C[row][col] = 0;
        }
    }

    // Print A and B
    output_matrix("A", (long*)A, MATRIX_SIZE, MATRIX_SIZE);
    output_matrix("B", (long*)B, MATRIX_SIZE, MATRIX_SIZE);

    for (long i = 0; i < MATRIX_SIZE; i++) {
        for (long j = 0; j < MATRIX_SIZE; j++) {
            for (long k = 0; k < MATRIX_SIZE; k++) {
                C[i][j] = C[i][j] + A[i][k] * B[k][j];
            }
        }

        MATRIX_POSITION = i;

        print_string(" Row done\n");
    }

    output_matrix("C = A*B", (long*)C, MATRIX_SIZE, MATRIX_SIZE);
}
