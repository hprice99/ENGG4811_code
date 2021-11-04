# ENGG4811 RISC-V multi-softcore processor project

## Implementing multicast communication in a resource-efficient network-on-chip

## Student details

Name: Harrison Price

Student number: 44092410

Supervisor: Dr Matthew D’Souza

## Project overview
This repository contains the code written by Harrison Price (student number 44092410) for the completion of ENGG4811 at the University of Queensland in Semesters One and Two, 2021, as part of the completion of a Bachelor of Engineering (Honours) majoring in Computer and Electrical Engineering.
The field of study for this project was a RISC-V multi-softcore processor system implemented on an FPGA.
The chosen topic for this project was
> Implementing multicast communication in a resource-efficient network-on-chip

### Network-on-chip
This project involved designing a network-on-chip to facilitate communication between RISC-V softcore processors implemented on an FPGA.
This network was based on Hoplite, a resource-efficient network-on-chip using a deflected torus topology developed by Nachiket Kapre and Jan Gray [1].
A base Hoplite network was created to support unicast communication between softcore processors.
This network was then augmented with optional multicast clusters, allowing for messages to be delivered to multiple processors in the same clock cycle.

### RISC-V softcore processor
This project was implemented on a Nexys 4 DDR FPGA Development Board, which has a Xilinx XC7A-1CSG324C FPGA.
This FPGA has 15,850 logic slices, which is small relative to other FPGAs that have been used for network-on-chip design.
Furthermore, in this system, the processing elements that communicate with one another are RISC-V softcore processors.
These processors can require large amounts of FPGA resources to implement.

In order to facilitate the design of a network-on-chip used in a system of multiple RISC-V softcore processors, a RISC-V softcore processor with light resource usage was required.
PicoRV32 was ultimately selected due to its ability to implement the RISC-V integer instruction set architecture with the integer multiplication and division extension while using 2019 look-up tables [2].
It is available under the ISC license [here](https://github.com/cliffordwolf/picorv32).

### Fox's algorithm
In order to test the performance of the network-on-chip in a system of RISC-V softcore processors, Fox's algorithm was implemented.
Fox's algorithm is a single program, multiple data method for distributing the computation of the product of two square matrices **A** and **B** across a square grid of p processors [3].
Each processor is responsible for computing an square submatrix of size n/sqrt(p) in the final matrix product.
This algorithm computes the matrix product **AB** in sqrt(p) stages.
In each stage one processor in each row broadcasts its **A** submatrix to all processors in the same row.
The product **AB** of the submatrices in each processor is then calculated and added to the existing result.
At the end of the stage, each processor sends its **B** submatrix up its column.

This project implemented Fox's algorithm on a network of PicoRV32 RISC-V softcore processors which communicate through the network-on-chip that was designed.
Networks-on-chip with and without multicast commuincation functionality were both tested, and the performance of each system was analysed both in terms of computation time and FPGA resource utilisation. 

## Folder structure
This repository is organised into the following directories
### `constraints`
This directory contains the constraint files used to connect the ports of the VHDL top modules for each design (saved in files named `*_board_top.vhd`) to the pins and ports on the Nexys 4 DDR FPGA Development Board.

### `firmware`
This directory contains all files related to the firmware run on each PicoRV32 RISC-V softcore processor.
These files include the C code used to implement Fox's algorithm and define common library functions, linker scripts to map the `.memory` section of the firmware to a memory address, and assembly scripts to set the stack pointer when the cores are initialised. 

### `hdl`
This directory contains all hardware components developed in this project, as well as the testbenches used to simulate the behaviour of these modules.

### `results`
This directory contains the simulation and implementation results used to evaluate each of the systems that was designed. 

### `scripts`
This directory contains Python scripts used to generate the memory initialisation files and configuration headers used by the project.
It also includes Jinja2 templates for these configuration headers, as well as YAML configuration files to define the parameters used by each project.
These scripts are used to create a memory initialisation file containing the **A** and **B** matrices that are multiplied in the firmware, and create firmware and hardware configuration headers that remain synchronised.

### `vivado`
This directory contains the `.tcl` scripts that may be used to generate the Vivado projects required to synthesise and implement each design.
Waveform configuration files used in simulations are also saved in this directory.


## Build instructions
### Vivado project
This project was created with the Vivado 2020.2 Design Suite.
To build the project in Vivado, open the Vivado GUI and open the TCL console (accessible through the Window menu).
In the TCL console, navigate to the `vivado/<project>` folder in the repository (using `cd`) and run `source build.tcl`.

### RISC-V GNU toolchain installation
Building the firmware for this project requires the RISC-V GNU toolchain with the RV32IM instruction set architecture to be installed.
The following commands can be run to download and install this toolchain in the `/opt/risc32i` directory

```bash
# Ubuntu packages needed:
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev \
        libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev git libexpat1-dev

sudo mkdir /opt/riscv32i
sudo chown $USER /opt/riscv32i

git clone https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-rv32i
cd riscv-gnu-toolchain-rv32i
git checkout 411d134
git submodule update --init --recursive
cd riscv32i
mkdir build; cd build
../configure --with-arch=rv32im --prefix=/opt/riscv32i
make -j$(nproc)
```

### Firmware
With the RISC-V GNU toolchain installed, all firmware, HDL packages and headers, and memory initialisation files can be built by running `make all` from the repository root directory.

## References
[1] N. Kapre and J. Gray, “Hoplite: Building austere overlay NoCs for FPGAs,” FPL, pp. 1–8, 2015, doi: 10.1109/FPL.2015.7293956.

[2] C. Wolf, “picorv32,” Mar. 16, 2021. https://github.com/cliffordwolf/picorv32 (accessed Mar. 18, 2021).


[3] P. S. Pacheco, Parallel programming with MPI. San Francisco, Calif.: Morgan Kaufmann Publishers, 1997.

