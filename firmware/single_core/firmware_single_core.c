#include "io.h"
#include "matrix_config.h"
#include "print.h"
#include "matrix.h"

#define LOOP_DELAY      40000000

#define MAX_ENTRY 10

long A[MATRIX_SIZE * MATRIX_SIZE];
long B[MATRIX_SIZE * MATRIX_SIZE];
long C[MATRIX_SIZE * MATRIX_SIZE];

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

void createC(void) {

    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {

            int index = row * MATRIX_SIZE + col;

            C[index] = 0;
        }
    }
}

void main(void) {
    int switchValue = 0;

    int ledValue = 1;
    LED_OUTPUT = ledValue;

    createA();
    createB();
    createC();

    multiply_matrices(A, B, C);

    output_matrix("C = A*B", (long*)C, MATRIX_SIZE, MATRIX_SIZE);
    print_string("Matrix multiplication completed\n");

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
