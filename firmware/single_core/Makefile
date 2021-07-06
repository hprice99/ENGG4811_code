TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
LIB = ../lib
CFLAGS = -march=rv32im
SINGLE_CORE_MEM_SIZE=16384
IO_CONFIG = IO_CONFIG

.PHONY: all
all: firmware_single_core

firmware_single_core: firmware_single_core.c io.h $(LIB)/print.c $(LIB)/print.h $(LIB)/matrix.c $(LIB)/matrix.h firmware_single_core.lds firmware_single_core.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(IO_CONFIG) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_single_core.elf firmware_single_core.S firmware_single_core.c $(LIB)/print.c $(LIB)/matrix.c --std=gnu99 -Wl,-Bstatic,-T,firmware_single_core.lds,-Map,firmware_single_core.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_single_core.elf firmware_single_core.bin && python3 ../makehex.py firmware_single_core.bin $(SINGLE_CORE_MEM_SIZE) > firmware_single_core.hex

clean:
	rm *.bin *.hex *.elf *.map
