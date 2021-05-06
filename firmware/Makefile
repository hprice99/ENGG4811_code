TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
MEM_SIZE=1024
SINGLE_CORE_MEM_SIZE=16384

.PHONY: all
all: firmware firmware_single_core

firmware: firmware.c firmware.lds firmware.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware.elf firmware.S firmware.c --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map,--strip-debug -lgcc && /opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin && python3 makehex.py firmware.bin $(MEM_SIZE) > firmware.hex

firmware_single_core: firmware_single_core.c firmware_single_core.lds firmware_single_core.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware_single_core.elf firmware_single_core.S firmware_single_core.c --std=gnu99 -Wl,-Bstatic,-T,firmware_single_core.lds,-Map,firmware_single_core.map,--strip-debug -lgcc && /opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary firmware_single_core.elf firmware_single_core.bin && python3 makehex.py firmware_single_core.bin $(SINGLE_CORE_MEM_SIZE) > firmware_single_core.hex

clean:
	rm *.bin *.hex *.elf *.map
