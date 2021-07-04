MAKE = make
FIRMWAREDIR = firmware

.PHONY: all
all: sw

sw:
	cd $(FIRMWAREDIR) && $(MAKE) all

clean: 
	cd $(FIRMWAREDIR) && $(MAKE) clean