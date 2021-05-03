MAKE = make
FIRMWAREDIR = firmware

.PHONY: all
all: sw sw_single_core

sw:
	cd $(FIRMWAREDIR) && $(MAKE) firmware

sw_single_core:
	cd $(FIRMWAREDIR) && $(MAKE) firmware_single_core

clean: sw_clean

sw_clean:
	cd $(FIRMWAREDIR) && $(MAKE) clean