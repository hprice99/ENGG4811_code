#ifndef MATRIX_CONFIG_H
#define MATRIX_CONFIG_H

// Size of matrices used by each node
#define FOX_MATRIX_SIZE     {{ foxNetwork.foxMatrixSize }}
#define MATRIX_SIZE         FOX_MATRIX_SIZE

// Size of total matrix
#define TOTAL_MATRIX_SIZE       {{ foxNetwork.totalMatrixSize }}
#define TOTAL_MATRIX_ELEMENTS   (TOTAL_MATRIX_SIZE * TOTAL_MATRIX_SIZE)

#endif
