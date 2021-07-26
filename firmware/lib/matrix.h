#ifndef MATRIX_H
#define MATRIX_H

#ifdef IO_CONFIG
#include "io.h"
#endif

#ifdef MATRIX_CONFIG
#include "matrix_config.h"
#endif

#ifndef MATRIX_ROW_END
#define MATRIX_ROW_END (*(volatile char*)0x10000000)
#endif

#ifndef MATRIX_END
#define MATRIX_END (*(volatile char*)0x20000000)
#endif

#ifndef MATRIX_POSITION
#define MATRIX_POSITION (*(volatile char*)0x30000000)
#endif

#ifndef MATRIX_OUTPUT
#define MATRIX_OUTPUT (*(volatile long*)0x40000000)
#endif

#ifndef MATRIX_SIZE
#error MATRIX_SIZE not defined
#endif

void print_matrix(long* matrix, int rows, int cols);

void output_digit(long digit);

void output_matrix(char* label, long* matrix, int rows, int cols);

void multiply_matrices(long* A, long* B);

#endif
