#ifndef PRINT_H
#define PRINT_H

void print_char(char c);

void print_string(const char *s);

/* reverse:  reverse string s in place */
void reverse(char* s, int length);

/* itoa:  convert n to characters in s */
void itoa(long n, char s[]);

#endif