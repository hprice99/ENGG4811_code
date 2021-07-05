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

/* reverse:  reverse string s in place */
void reverse(char* s, int length);

/* itoa:  convert n to characters in s */
void itoa(long n, char s[]);

#endif