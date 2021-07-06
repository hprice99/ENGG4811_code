TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
MEM_SIZE = 1024

LIB = ../lib
IO_CONFIG = IO_CONFIG

PROJ_NAME = riscv_hoplite_test

.PHONY: all
all: firmware_$(PROJ_NAME)_led firmware_$(PROJ_NAME)_switch

firmware_$(PROJ_NAME)_led: firmware_$(PROJ_NAME)_led.c io.h $(LIB)/print.c $(LIB)/print.h firmware_$(PROJ_NAME)_led.lds firmware_$(PROJ_NAME)_led.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(IO_CONFIG) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_$(PROJ_NAME)_led.elf firmware_$(PROJ_NAME)_led.S firmware_$(PROJ_NAME)_led.c $(LIB)/print.c --std=gnu99 -Wl,-Bstatic,-T,firmware_$(PROJ_NAME)_led.lds,-Map,firmware_$(PROJ_NAME)_led.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_$(PROJ_NAME)_led.elf firmware_$(PROJ_NAME)_led.bin && python3 ../makehex.py firmware_$(PROJ_NAME)_led.bin $(MEM_SIZE) > firmware_$(PROJ_NAME)_led.hex

firmware_$(PROJ_NAME)_switch: firmware_$(PROJ_NAME)_switch.c io.h $(LIB)/print.c $(LIB)/print.h firmware_$(PROJ_NAME)_switch.lds firmware_$(PROJ_NAME)_switch.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(IO_CONFIG) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_$(PROJ_NAME)_switch.elf firmware_$(PROJ_NAME)_switch.S firmware_$(PROJ_NAME)_switch.c $(LIB)/print.c --std=gnu99 -Wl,-Bstatic,-T,firmware_$(PROJ_NAME)_switch.lds,-Map,firmware_$(PROJ_NAME)_switch.map,--strip-debug -lgcc && $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_$(PROJ_NAME)_switch.elf firmware_$(PROJ_NAME)_switch.bin && python3 ../makehex.py firmware_$(PROJ_NAME)_switch.bin $(MEM_SIZE) > firmware_$(PROJ_NAME)_switch.hex

clean:
	rm *.bin *.hex *.elf *.map
