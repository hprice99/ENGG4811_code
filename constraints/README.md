# `ENGG4811_code/constraints`
This directory contains the constraint files that connect the pins on the Nexys 4 DDR FPGA Development Board to the ports in the VHDL top modules for each design.
The top modules of the design for each project are stored in the `ENGG4811_code/hdl/<project>/src/` directory, and are saved in files called `<project>_board_top.vhd`.

These files are automatically imported when a project is build from its `build.tcl` script stored in the `vivado` directory.