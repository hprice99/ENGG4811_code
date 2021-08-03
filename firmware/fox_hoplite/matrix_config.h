#ifndef MATRIX_CONFIG_H
#define MATRIX_CONFIG_H

// Size of matrices used by each node
// Equivalent to FOX_MATRIX_SIZE in fox_defs.vhd
#define FOX_MATRIX_SIZE 2
#define MATRIX_SIZE     FOX_MATRIX_SIZE

// Size of total matrix
// Equivalent to TOTAL_MATRIX_SIZE in fox_defs.vhd
#define TOTAL_MATRIX_SIZE   4
#define TOTAL_MATRIX_ELEMENTS   (TOTAL_MATRIX_SIZE * TOTAL_MATRIX_SIZE)

#endif