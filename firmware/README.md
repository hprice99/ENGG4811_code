# `ENGG4811_code/firmware`
This directory contains all files related to the firmware run on each PicoRV32 RISC-V softcore processor.

The files for each project are stored in a separate directory.
Each project directory includes the C code used to implement the program, linker scripts to map the `.memory` section of the firmware executable to a memory address in hardware, assembly scripts to set the stack pointer when the core is initialised, and a Makefile to build the firmware executables. 

## Directories
### `fox_hoplite`
This directory contains the firmware files used by the `fox_hoplite` project.
This project implements Fox’s algorithm using a unicast-only network-on-chip.

### `fox_hoplite_multicast`
This directory contains the firmware files used by the `fox_hoplite_multicast` project.
This project implements Fox’s algorithm using a network-on-chip with a dedicated multicast network layer.

### `lib`
This directory contains files that define library functions that are commonly used by each project.
This includes functions to perform matrix multiplication through a serial algorithm, and functions to print characters from a PicoRV32 core.

### `riscv_hoplite_test`
This directory contains the firmware files used by the `riscv_hoplite_test` project.
This project was used to test the network-on-chip that was designed by distributing the control of four LEDs over four PicoRV32 processors.

### `single_core`
This directory contains the firmware files used by the `single_core` project.
This project implements matrix product calculations on a single PicoRV32 core using a serial algorithm.

## Build instructions
Before the firmware can be built, it is important that the C and Makefile headers are built.
This is done by running `make` from the `ENGG4811_code/scripts` directory.
The firmware executables can then be built by running `make all` from this directory.