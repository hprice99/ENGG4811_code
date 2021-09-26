`ifndef IO_VH
`define IO_VH

// Character output
`define CHAR_OUTPUT      32'h1000_0000
`define CHAR_OUTPUT_READY_INPUT      32'h1000_0010

// PE to network
`define MESSAGE_OUT_READY_INPUT      32'h2000_0000
`define X_COORD_OUTPUT      32'h2000_0010
`define Y_COORD_OUTPUT      32'h2000_0020
`define MULTICAST_GROUP_OUTPUT      32'h2000_0030
`define DONE_FLAG_OUTPUT      32'h2000_0040
`define RESULT_FLAG_OUTPUT      32'h2000_0050
`define MATRIX_TYPE_OUTPUT      32'h2000_0060
`define MATRIX_X_COORD_OUTPUT      32'h2000_0070
`define MATRIX_Y_COORD_OUTPUT      32'h2000_0080
`define MATRIX_ELEMENT_OUTPUT      32'h2000_0090
`define PACKET_COMPLETE_OUTPUT      32'h2000_0100

// LEDs
`define LED_OUTPUT      32'h3000_0000

// Network to PE
`define MESSAGE_VALID_INPUT      32'h4000_0000
`define MESSAGE_IN_AVAILABLE_INPUT      32'h4000_0010
`define MULTICAST_GROUP_INPUT      32'h4000_0020
`define DONE_FLAG_INPUT      32'h4000_0030
`define RESULT_FLAG_INPUT      32'h4000_0040
`define MATRIX_TYPE_INPUT      32'h4000_0050
`define MATRIX_X_COORD_INPUT      32'h4000_0060
`define MATRIX_Y_COORD_INPUT      32'h4000_0070
`define MATRIX_ELEMENT_INPUT      32'h4000_0080
`define MESSAGE_READ_OUTPUT      32'h4000_0090

// Node details
`define X_COORD_INPUT      32'h5000_0000
`define Y_COORD_INPUT      32'h5000_0010
`define NODE_NUMBER_INPUT      32'h5000_0020
`define MATRIX_X_OFFSET_INPUT      32'h5000_0030
`define MATRIX_Y_OFFSET_INPUT      32'h5000_0040
`define MATRIX_INIT_FROM_FILE_INPUT      32'h5000_0050

// Matrix
`define MATRIX_OUTPUT      32'h6000_0000
`define MATRIX_END_ROW_OUTPUT      32'h6000_0010
`define MATRIX_END_OUTPUT      32'h6000_0020
`define FOX_MATRIX_SIZE_INPUT      32'h6000_0030

// Network details
`define FOX_NETWORK_STAGES_INPUT      32'h7000_0000
`define RESULT_X_COORD_INPUT      32'h7000_0010
`define RESULT_Y_COORD_INPUT      32'h7000_0020
`define ROM_X_COORD_INPUT      32'h7000_0030
`define ROM_Y_COORD_INPUT      32'h7000_0040

`endif