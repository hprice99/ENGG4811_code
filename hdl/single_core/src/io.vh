`ifndef IO_VH
`define IO_VH

// Character output
`define CHAR_OUTPUT      32'h1000_0000
`define CHAR_OUTPUT_READY_INPUT      32'h1000_0010


// LEDs
`define LED_OUTPUT      32'h3000_0000


// Node details
`define MATRIX_INIT_FROM_FILE_INPUT      32'h5000_0000

// Matrix
`define MATRIX_OUTPUT      32'h6000_0000
`define MATRIX_END_ROW_OUTPUT      32'h6000_0010
`define MATRIX_END_OUTPUT      32'h6000_0020


`endif