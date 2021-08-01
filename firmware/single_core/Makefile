TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
MEM_SIZE = 16384

LIB = ../lib
LIB_SRCS = $(LIB)/print.c $(LIB)/matrix.c
LIB_HEADERS = $(LIB)/print.h $(LIB)/matrix.h
CONFIG_HEADERS = io.h matrix_config.h

IO_CONFIG = IO_CONFIG
MATRIX_CONFIG = MATRIX_CONFIG
MATRIX_POSITION_OUT_ENABLED = MATRIX_POSITION_OUT_ENABLED
DEBUG_PRINT = DEBUG_PRINT

PROJ_NAME = single_core

.PHONY: all
all: firmware_$(PROJ_NAME)

debug: firmware_$(PROJ_NAME)_debug

firmware_$(PROJ_NAME): firmware_$(PROJ_NAME).c $(LIB_SRCS) $(LIB_HEADERS) $(CONFIG_HEADERS) firmware_$(PROJ_NAME).lds firmware_$(PROJ_NAME).S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(IO_CONFIG) -D$(MATRIX_CONFIG) -D$(MATRIX_POSITION_OUT_ENABLED) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).S firmware_$(PROJ_NAME).c $(LIB_SRCS) --std=gnu99 -Wl,-Bstatic,-T,firmware_$(PROJ_NAME).lds,-Map,firmware_$(PROJ_NAME).map,--strip-debug -lgcc \
	&& $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).bin \
	&& python3 ../makehex.py firmware_$(PROJ_NAME).bin $(MEM_SIZE) > firmware_$(PROJ_NAME).hex

firmware_$(PROJ_NAME)_debug: firmware_$(PROJ_NAME).c $(LIB_SRCS) $(LIB_HEADERS) $(CONFIG_HEADERS) firmware_$(PROJ_NAME).lds firmware_$(PROJ_NAME).S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(DEBUG_PRINT) -D$(IO_CONFIG) -D$(MATRIX_CONFIG) -D$(MATRIX_POSITION_OUT_ENABLED) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).S firmware_$(PROJ_NAME).c $(LIB_SRCS) --std=gnu99 -Wl,-Bstatic,-T,firmware_$(PROJ_NAME).lds,-Map,firmware_$(PROJ_NAME).map,--strip-debug -lgcc \
	&& $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).bin \
	&& python3 ../makehex.py firmware_$(PROJ_NAME).bin $(MEM_SIZE) > firmware_$(PROJ_NAME).hex

clean:
	rm *.bin *.hex *.elf *.map

