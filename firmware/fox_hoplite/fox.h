#ifndef FOX_H
#define FOX_H

#include <stdbool.h>

#include "network.h"
#include "matrix.h"

extern int foxStages;
extern int xOffset;
extern int yOffset;

extern int resultXCoord;
extern int resultYCoord;

extern long my_A[MATRIX_SIZE * MATRIX_SIZE];

extern long stage_A[MATRIX_SIZE * MATRIX_SIZE];
extern long stage_B[MATRIX_SIZE * MATRIX_SIZE];

extern long result_C[MATRIX_SIZE * MATRIX_SIZE];

#define FOX_NETWORK_WAIT    1000000000

enum FoxError {
    FOX_ALGORITHM_ERROR         = -4,
    FOX_ASSIGNMENT_ERROR        = -3,
    FOX_NETWORK_TIMEOUT_ERROR   = -2,
    FOX_NETWORK_ERROR           = -1,
    FOX_SUCCESS                 = 0
};

enum FoxError send_A(int my_x_coord, int my_y_coord, int fox_rows);

enum FoxError send_B(int my_x_coord, int my_y_coord, int fox_cols);

enum FoxError assign_element(struct MatrixPacket packet);

enum FoxError receive_matrix(enum MatrixType matrixType);

bool is_broadcast_stage(int my_x_coord, int my_y_coord, int stage);

enum FoxError fox_algorithm(int my_row, int my_col);

#endif