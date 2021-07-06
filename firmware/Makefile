MAKE = make
SINGLE_CORE_DIR = single_core
HOPLITE_DIR = fox_hoplite
RISCV_HOPLITE_TEST_DIR = riscv_hoplite_test

.PHONY: all
all: build_single_core build_hoplite build_riscv_hoplite_test

build_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) all

build_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) all

build_riscv_hoplite_test:
	cd $(RISCV_HOPLITE_TEST_DIR) && $(MAKE) all

clean: clean_single_core clean_hoplite clean_riscv_hoplite_test

clean_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) clean

clean_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) clean

clean_riscv_hoplite_test:
	cd $(RISCV_HOPLITE_TEST_DIR) && $(MAKE) clean