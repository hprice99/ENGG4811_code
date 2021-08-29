all: io_fox_hoplite config_fox_hoplite

.PHONY: all io_fox_hoplite config_fox_hoplite

io_fox_hoplite:
	python3 io.py fox_hoplite

config_fox_hoplite:
	python3 fox_network_generate.py fox_hoplite

clean: 
	-rm *.h *.vh