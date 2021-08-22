all: io config

.PHONY: all io config

io:
	python3 io.py

config:
	python3 fox_network_generate.py

# TODO Clean headers in firmware and hdl directories
clean: 
	-rm *.h *.vh