MAKE = make
SINGLE_CORE_DIR = single_core
HOPLITE_DIR = fox_hoplite

.PHONY: all
all: build_single_core build_hoplite

build_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) all

build_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) all

clean: clean_single_core clean_hoplite

clean_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) clean

clean_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) clean