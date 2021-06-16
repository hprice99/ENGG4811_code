MAKE = make
FIRMWAREDIR = firmware

.PHONY: all
all: sw_hoplite sw_single_core

sw_hoplite:
	cd $(FIRMWAREDIR) && $(MAKE) firmware_hoplite

sw_single_core:
	cd $(FIRMWAREDIR) && $(MAKE) firmware_single_core

clean: sw_clean

sw_clean:
	cd $(FIRMWAREDIR) && $(MAKE) clean