// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Apr  9 15:09:06 2021
// Host        : parallels-Parallels-Virtual-Platform running 64-bit Ubuntu 20.04.2 LTS
// Command     : write_verilog -force -mode synth_stub /home/parallels/Desktop/PicoRV/ENGG4811_code/ip/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2020.2" *)
module ila_0(clk, probe0, probe1, probe2)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[7:0],probe1[0:0],probe2[0:0]" */;
  input clk;
  input [7:0]probe0;
  input [0:0]probe1;
  input [0:0]probe2;
endmodule
