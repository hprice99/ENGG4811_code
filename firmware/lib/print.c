#include "print.h"

void print_char(char c)
{
    CHAR_OUTPUT = c;
}

void print_string(const char *s)
{
    while (*s) {
        print_char(*s);
        *s++;
    }
}

void *memcpy(void *dest, const void *src, int n) {
    while (n) {
        n--;
        ((char*)dest)[n] = ((char*)src)[n];
    }
    return dest;
}

// TODO Fix so that division is not required
/*
void print_dec(unsigned long val) {

    char buffer[10];
    char *p = buffer;

    while (val || p == buffer) {
        *(p++) = val % 10;
        val = val / 10;
    }

    while (p != buffer) {
        print_char('0' + *(--p));
    }
}
*/

void print_hex(unsigned long val, int digits) {
    for (int i = (4*digits)-4; i >= 0; i -= 4) {
        print_char("0123456789ABCDEF"[(val >> i) % 16]);
    }
}
