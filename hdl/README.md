# `ENGG4811_code/hdl`
This directory contains all files used to implement the hardware modules used by each project.

The files for each project are stored in a separate directory.
Directories have also been created to store common hardware components. 

Each directory contains `src` and `tb` folders which contain the VHDL behavioural module definitions, and the testbenches used to test these modules, respectively. 

## Directories
### `building_blocks`
This directory contains hardware modules commonly used in designs, such as synchronous FIFOs and block RAM-based ROM modules.

### `fox`
This directory contains the hardware modules commonly used by all systems that implement Fox’s algorithm.
This includes a `rom_burst` module used to instantiate a block RAM-based ROM that is used to initialise the matrices assigned to each processor.

### `fox_hoplite`
This directory contains the hardware used by the `fox_hoplite` project.
This project implements Fox’s algorithm using a unicast-only network-on-chip.

### `fox_hoplite_multicast`
This directory contains the hardware files used by the `fox_hoplite_multicast` project.
This project implements Fox’s algorithm using a network-on-chip with a dedicated multicast network layer.

### `hoplite`
This directory contains the hardware files used to implement a Hoplite network-on-chip, including each router design used and the network interface controller design.
All files in this directory may be used in another project to implement a network-on-chip.

### `ip`
This directory contains files used to instantiate the Xilinx IP used by these projects.
For these projects, only a clock divider IP block has been used to create a PLL-based clock divider.
This may be substituted with a functionally-equivalent module if these projects are implemented on a non-Xilinx FPGA.

### `picorv32`
This directory contains the hardware modules used to implement the PicoRV32 RISC-V softcore processor.

### `riscv_hoplite_test`
This directory contains the hardware files used by the `riscv_hoplite_test` project.
This project was used to test the network-on-chip that was designed by distributing the control of four LEDs over four PicoRV32 processors.

### `single_core`
This directory contains the hardware files used by the `single_core` project.
This project implements matrix product calculations on a single PicoRV32 core using a serial algorithm.

### `submodules`
This directory contains submodules used for common hardware components.
This includes a UART module, forked from [1].

## Build instructions
The hardware modules contained in this directory cannot be built by themselves.
Each project may be built in Vivado using the `build.tcl` scripts stored in the `ENGG4811_code/vivado/<project>` folders.

## References
[1] J. Cabal, Simple UART for FPGA. 2021. Accessed: Nov. 01, 2021. [Online]. Available: https://github.com/jakubcabal/uart-for-fpga
