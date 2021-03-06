`ifndef IO_VH
`define IO_VH

`define CHAR_OUTPUT     32'h1000_0000

// PE to network
`define MESSAGE_OUT_READY_INPUT    32'h2000_0000
`define X_COORD_OUTPUT              32'h2000_0010
`define Y_COORD_OUTPUT              32'h2000_0020
`define MESSAGE_OUTPUT              32'h2000_0030
`define PACKET_COMPLETE_OUTPUT      32'h2000_0040

// LEDs
`define LED_0_OUTPUT    32'h3000_0000
`define LED_1_OUTPUT    32'h3000_0010
`define LED_2_OUTPUT    32'h3000_0020
`define LED_3_OUTPUT    32'h3000_0030

`define SWITCH_INPUT            32'h4000_0000

// Network to PE
`define MESSAGE_VALID_INPUT         32'h5000_0000
`define MESSAGE_INPUT               32'h5000_0010
`define MESSAGE_IN_AVAILABLE_INPUT  32'h5000_0020

// Node details
`define X_COORD_INPUT           32'h6000_0000
`define Y_COORD_INPUT           32'h6000_0010
`define NODE_NUMBER_INPUT       32'h6000_0020

`endif