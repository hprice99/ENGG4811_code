# `ENGG4811_code/scripts`
This directory contains the Python scripts, Jinja2 templates, and YAML configuration files used to generate all headers, packages and memory initialisation files used by each project.

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

### `templates`
This directory contains the Jinja2 templates used to generate the headers and packages used by each project. 

## Build instructions
The headers and packages used by each system must be generated before the firmware is built, and the hardware implementation is completed. 
These may be generated by running `make all` from this directory.