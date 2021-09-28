all: io_fox_hoplite config_fox_hoplite io_fox_hoplite_multicast config_fox_hoplite_multicast io_single_core config_single_core

.PHONY: all io_fox_hoplite config_fox_hoplite io_fox_hoplite_multicast config_fox_hoplite_multicast io_single_core config_single_core

io_fox_hoplite:
	python3 io.py fox_hoplite

config_fox_hoplite:
	python3 fox_network_generate.py fox_hoplite

io_fox_hoplite_multicast:
	python3 io.py fox_hoplite_multicast

config_fox_hoplite_multicast:
	python3 fox_network_generate.py fox_hoplite_multicast

io_single_core:
	python3 io.py single_core

config_single_core:
	python3 fox_network_generate.py single_core

clean: 
	-rm *.h *.vh