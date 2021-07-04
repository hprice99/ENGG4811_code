TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
HOPLITE_MEM_SIZE=1024

.PHONY: all
all: firmware_hoplite

firmware_hoplite: firmware_hoplite.c firmware_hoplite.lds firmware_hoplite.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware_hoplite.elf firmware_hoplite.S firmware_hoplite.c --std=gnu99 -Wl,-Bstatic,-T,firmware_hoplite.lds,-Map,firmware_hoplite.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_hoplite.elf firmware_hoplite.bin && python3 ../makehex.py firmware_hoplite.bin $(HOPLITE_MEM_SIZE) > firmware_hoplite.hex

clean:
	rm *.bin *.hex *.elf *.map
