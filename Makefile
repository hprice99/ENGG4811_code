MAKE = make
FIRMWAREDIR = firmware

.PHONY: all
all: sw

sw:
	cd $(FIRMWAREDIR) && $(MAKE) all

debug:
	cd $(FIRMWAREDIR) && $(MAKE) debug

clean: 
	cd $(FIRMWAREDIR) && $(MAKE) clean