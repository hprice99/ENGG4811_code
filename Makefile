MAKE = make
FIRMWAREDIR = firmware

sw:
	cd $(FIRMWAREDIR) && $(MAKE) firmware

clean: sw_clean
	

sw_clean:
	cd $(FIRMWAREDIR) && $(MAKE) clean