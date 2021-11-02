# `ENGG4811_code/results`
This directory contains the simulation and implementation results used to evaluate each of the systems that was designed.

Each system was implemented in hardware to compute the product of 8x8, 16x16, 32x32, and 40x40 matrices.
Hierarchical utilisation reports for each system were saved, and are stored in this directory.

Each system was also tested in simulations to compare the time taken by each system to compute matrix products of various sizes.
These files are stored in the `.ods` format, which may be opened in Microsoft Excel, LibreOffice Calc, or OpenOffice Calc.

## Directories
### `multicast`
This directory contains the results for the `fox_hoplite_multicast` project.
This project implements Fox’s algorithm using a network-on-chip with a dedicated multicast network layer.

### `single_core`
This directory contains the results for the `single_core` project.
This project implements matrix product calculations on a single PicoRV32 core using a serial algorithm.

### `unicast`
This directory contains the results for the `fox_hoplite` project.
This project implements Fox’s algorithm using a unicast-only network-on-chip.