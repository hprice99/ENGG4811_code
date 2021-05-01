TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
MEM_SIZE=1024

firmware: firmware.c firmware.lds firmware.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Os -ffreestanding -nostdlib -o firmware.elf firmware.S firmware.c --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map,--strip-debug -lgcc && /opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin && python3 makehex.py firmware.bin $(MEM_SIZE) > firmware.hex

clean:
	rm firmware.bin firmware.hex firmware.elf firmware.map