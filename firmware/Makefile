TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
HOPLITE_MEM_SIZE=1024
SINGLE_CORE_MEM_SIZE=16384

.PHONY: all
all: firmware_hoplite firmware_single_core

firmware_hoplite: firmware_hoplite.c firmware_hoplite.lds firmware_hoplite.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware_hoplite.elf firmware_hoplite.S firmware_hoplite.c --std=gnu99 -Wl,-Bstatic,-T,firmware_hoplite.lds,-Map,firmware_hoplite.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_hoplite.elf firmware_hoplite.bin && python3 makehex.py firmware_hoplite.bin $(HOPLITE_MEM_SIZE) > firmware_hoplite.hex

firmware_single_core: firmware_single_core.c firmware.h print.c print.h matrix.c matrix.h firmware_single_core.lds firmware_single_core.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware_single_core.elf firmware_single_core.S firmware_single_core.c print.c matrix.c --std=gnu99 -Wl,-Bstatic,-T,firmware_single_core.lds,-Map,firmware_single_core.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_single_core.elf firmware_single_core.bin && python3 makehex.py firmware_single_core.bin $(SINGLE_CORE_MEM_SIZE) > firmware_single_core.hex

clean:
	rm *.bin *.hex *.elf *.map
