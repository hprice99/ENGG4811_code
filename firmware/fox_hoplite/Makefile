TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS = -march=rv32im
MEM_SIZE = 1024

LIB = ../lib
LIB_SRCS = $(LIB)/print.c $(LIB)/network.c
LIB_HEADERS = $(LIB)/print.h $(LIB)/network.h

IO_CONFIG = IO_CONFIG

PROJ_NAME = hoplite

.PHONY: all
all: firmware_$(PROJ_NAME)

firmware_$(PROJ_NAME): firmware_$(PROJ_NAME).c io.h $(LIB_SRCS) $(LIB_HEADERS) firmware_$(PROJ_NAME).lds firmware_$(PROJ_NAME).S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -D$(IO_CONFIG) -I. -I$(LIB) -Os -ffreestanding -nostdlib -o firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).S firmware_$(PROJ_NAME).c $(LIB_SRCS) --std=gnu99 -Wl,-Bstatic,-T,firmware_$(PROJ_NAME).lds,-Map,firmware_$(PROJ_NAME).map,--strip-debug -lgcc \
	&& $(TOOLCHAIN_PREFIX)objcopy -O binary firmware_$(PROJ_NAME).elf firmware_$(PROJ_NAME).bin \
	&& python3 ../makehex.py firmware_$(PROJ_NAME).bin $(MEM_SIZE) > firmware_$(PROJ_NAME).hex

clean:
	rm *.bin *.hex *.elf *.map
