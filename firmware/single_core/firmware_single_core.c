#include "io.h"
#include "print.h"
#include "matrix.h"

#define LOOP_COUNTER 1000000000

#define MAX_ENTRY 10

long A[MATRIX_SIZE * MATRIX_SIZE];
long B[MATRIX_SIZE * MATRIX_SIZE];

void createA(void) {

    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            if (row < 50) {
                A[index] = row + 1;
            } else {
                A[index] = row - 50;
            }
        }
    }

    output_matrix("A", (long*)A, MATRIX_SIZE, MATRIX_SIZE);
}

void createB(void) {

    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            if (col < 50) {
                B[index] = col + 1;
            } else {
                B[index] = col - 50;
            }
        }
    }

    output_matrix("B", (long*)B, MATRIX_SIZE, MATRIX_SIZE);
}

void main(void) {
    int ledValue = 0;

    int switchValue = 0;

    int i = 0;

    LED = ledValue;

    createA();
    createB();

    multiply_matrices(A, B);

    print_string("Matrix multiplication completed\n");

    while (1) {

        LED = ledValue;
        switchValue = SWITCH;
        ledValue = switchValue;
    }
}
