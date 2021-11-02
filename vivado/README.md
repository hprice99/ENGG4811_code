# `ENGG4811_code/vivado`
This directory contains the `.tcl` scripts that may be used to generate the Vivado projects required to synthesise and implement each design. Waveform configuration files used in simulations are also saved in this directory.

## Directories
### `fox_hoplite`
This directory contains the YAML configuration files used by the `fox_hoplite` project.
This project implements Fox’s algorithm using a unicast-only network-on-chip.

### `fox_hoplite_multicast`
This directory contains the YAML configuration files used by the `fox_hoplite_multicast` project.
This project implements Fox’s algorithm using a network-on-chip with a dedicated multicast network layer.

### `single_core`
This directory contains the YAML configuration files used by the `single_core` project.
This project implements matrix product calculations on a single PicoRV32 core using a serial algorithm.

## Build instructions
To build each project, open the Vivado GUI and the TCL console (accessible through the Window menu).
In the TCL console, navigate to the `ENGG4811_code/vivado/<project>` directory using the `cd` command, then run `source build.tcl`.
