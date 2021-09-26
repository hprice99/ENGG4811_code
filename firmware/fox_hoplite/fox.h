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

#ifdef RESULT
extern long total_C[TOTAL_MATRIX_SIZE * TOTAL_MATRIX_SIZE];
#endif

#define FOX_NETWORK_WAIT    1000000000

#define FOX_COORDINATE_TO_INDEX(x, y)   (y * MATRIX_SIZE + x)
#define RESULT_COORDINATE_TO_INDEX(x, y)   (y * TOTAL_MATRIX_SIZE + x)

enum FoxError {
    FOX_ALGORITHM_ERROR         = -4,
    FOX_ASSIGNMENT_ERROR        = -3,
    FOX_NETWORK_TIMEOUT_ERROR   = -2,
    FOX_NETWORK_ERROR           = -1,
    FOX_SUCCESS                 = 0
};

enum FoxError receive_fox_packet(struct MatrixPacket* packet);

enum FoxError send_ready(int my_x_coord, int my_y_coord, 
        enum MatrixType matrixType, int dest_x_coord, int dest_y_coord);

bool is_a_broadcast_ready(int my_x_coord, int my_y_coord, int fox_rows);

enum FoxError send_A(int my_x_coord, int my_y_coord, int fox_rows);

bool is_b_send_ready(int my_x_coord, int my_y_coord, int fox_cols);

enum FoxError send_B(int my_x_coord, int my_y_coord, int fox_cols);

enum FoxError send_C(int my_x_coord, int my_y_coord);

enum FoxError assign_element(struct MatrixPacket packet);

enum FoxError receive_matrix(enum MatrixType matrixType);

#ifdef RESULT
enum FoxError receive_result(void);

enum FoxError assign_my_C(void);

enum FoxError assign_result(struct MatrixPacket packet);
#endif

int get_broadcast_stage_node(int my_x_coord, int my_y_coord, int stage);

enum FoxError fox_algorithm(int my_row, int my_col);

#endif