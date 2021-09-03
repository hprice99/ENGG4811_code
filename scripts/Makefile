all: io_fox_hoplite config_fox_hoplite io_fox_hoplite_multicast config_fox_hoplite_multicast

.PHONY: all io_fox_hoplite config_fox_hoplite io_fox_hoplite_multicast config_fox_hoplite_multicast

io_fox_hoplite:
	python3 io.py fox_hoplite

config_fox_hoplite:
	python3 fox_network_generate.py fox_hoplite

io_fox_hoplite_multicast:
	python3 io.py fox_hoplite_multicast

config_fox_hoplite_multicast:
	python3 fox_network_generate.py fox_hoplite_multicast

clean: 
	-rm *.h *.vh