#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "matrix.h"

#define LOOP_DELAY      40000000

#define MAX_ENTRY 10

long A[MATRIX_SIZE * MATRIX_SIZE];
long B[MATRIX_SIZE * MATRIX_SIZE];
long C[MATRIX_SIZE * MATRIX_SIZE];

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

    #ifdef DEBUG_PRINT
    print_matrix("A", A, MATRIX_SIZE, MATRIX_SIZE);
    #endif
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

    #ifdef DEBUG_PRINT
    print_matrix("B", B, MATRIX_SIZE, MATRIX_SIZE);
    #endif
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
    
    print_string("Single core ");
    print_dec(1);
    print_char('\n');

    int ledValue = 1;
    LED_OUTPUT = ledValue;

    createA();
    createB();
    createC();

    multiply_matrices(A, B, C);

    print_matrix("C", C, MATRIX_SIZE, MATRIX_SIZE);

    int loopCount = 0;
    int ledToggles = 0;

    print_string("\nLED ");

    if (ledValue == 0) {
        
        print_string("off, ");
    } else if (ledValue == 1) {

        print_string("on,  ");
    }

    print_string("ledToggles = ");
    print_dec(ledToggles);
    print_char('\n');

    while (1) {

        if (loopCount > LOOP_DELAY) {

            loopCount = 0;
            ledValue = 1 - ledValue;
            ledToggles++;

            LED_OUTPUT = ledValue;

            print_string("LED ");

            if (ledValue == 0) {
                
                print_string("off, ");
            } else if (ledValue == 1) {

                print_string("on,  ");
            }

            print_string("ledToggles = ");
            print_dec(ledToggles);
            print_char('\n');
        }

        loopCount++;
    }
}
