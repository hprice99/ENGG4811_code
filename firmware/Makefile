MAKE = make
SINGLE_CORE_DIR = single_core
HOPLITE_DIR = fox_hoplite

.PHONY: all
all: fw_single_core fw_hoplite

fw_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) all

fw_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) all

clean: single_core_clean hoplite_clean

single_core_clean:
	cd $(SINGLE_CORE_DIR) && $(MAKE) clean

hoplite_clean:
	cd $(HOPLITE_DIR) && $(MAKE) clean