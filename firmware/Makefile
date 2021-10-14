MAKE = make
SINGLE_CORE_DIR = single_core
HOPLITE_DIR = fox_hoplite
FOX_HOPLITE_MULTICAST_DIR = fox_hoplite_multicast
RISCV_HOPLITE_TEST_DIR = riscv_hoplite_test

.PHONY: all
all: build_single_core build_hoplite build_fox_hoplite_multicast build_riscv_hoplite_test

build_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) all

build_fox_hoplite_multicast:
	cd $(FOX_HOPLITE_MULTICAST_DIR) && $(MAKE) all

build_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) all

build_riscv_hoplite_test:
	cd $(RISCV_HOPLITE_TEST_DIR) && $(MAKE) all

debug: build_single_core_debug build_hoplite_debug build_fox_hoplite_multicast_debug build_riscv_hoplite_test_debug

build_hoplite_debug:
	cd $(HOPLITE_DIR) && $(MAKE) debug

build_fox_hoplite_multicast_debug:
	cd $(FOX_HOPLITE_MULTICAST_DIR) && $(MAKE) debug

build_single_core_debug:
	cd $(SINGLE_CORE_DIR) && $(MAKE) debug

build_riscv_hoplite_test_debug:
	cd $(RISCV_HOPLITE_TEST_DIR) && $(MAKE) debug

clean: clean_single_core clean_hoplite clean_fox_hoplite_multicast clean_riscv_hoplite_test

clean_hoplite:
	cd $(HOPLITE_DIR) && $(MAKE) clean

clean_fox_hoplite_multicast:
	cd $(FOX_HOPLITE_MULTICAST_DIR) && $(MAKE) clean

clean_single_core:
	cd $(SINGLE_CORE_DIR) && $(MAKE) clean

clean_riscv_hoplite_test:
	cd $(RISCV_HOPLITE_TEST_DIR) && $(MAKE) clean