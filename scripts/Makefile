.PHONY: all
all: io config

# TODO Add matrix target

io:
	python3 io.py

config:
	python3 fox_network_generate.py

# TODO Clean headers in firmware and hdl directories
clean: 
	rm *.h *.vh