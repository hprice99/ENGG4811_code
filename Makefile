MAKE = make
FIRMWARE_DIR = firmware
SCRIPT_DIR = scripts

all: scripts sw
.PHONY: all scripts sw

scripts:
	cd $(SCRIPT_DIR) && $(MAKE) all

sw:
	cd $(FIRMWARE_DIR) && $(MAKE) all

debug: scripts
	cd $(FIRMWARE_DIR) && $(MAKE) debug

clean: script_clean firmware_clean

script_clean:
	cd $(SCRIPT_DIR) && $(MAKE) clean

firmware_clean: 
	cd $(FIRMWARE_DIR) && $(MAKE) clean