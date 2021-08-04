#ifndef PRINT_H
#define PRINT_H

#ifdef IO_CONFIG
#include "io.h"
#endif

#ifndef CHAR_OUTPUT
#define CHAR_OUTPUT (*(volatile char*)0x10000000)
#endif

void print_char(char c);

void print_string(const char *s);

void *memcpy(void *dest, const void *src, int n);

void print_dec(unsigned long val);

void print_hex(unsigned long val, int digits);

#endif