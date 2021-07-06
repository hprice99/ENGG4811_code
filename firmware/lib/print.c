#include "print.h"

void print_char(char c)
{
    CHAR_OUTPUT = c;
}

void print_string(const char *s)
{
    while (*s) print_char(*s++);
}

/* reverse:  reverse string s in place */
void reverse(char* s, int length)
{
    int i, j;
    char c;

    // Reverse the string
    for (i = 0, j = length - 1; i < j; i++, j--) {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
}

/* itoa:  convert n to characters in s */
void itoa(long n, char s[]) {
    long i, sign;

    print_string("Sign ");

    if ((sign = n) < 0) { /* record sign */
        n = -n;          /* make n positive */
    }

    i = 0;

    print_string("Digits ");

    do {       /* generate digits in reverse order */
        s[i++] = n % 10 + '0';   /* get next digit */
    } while ((n /= 10) > 0);     /* delete it */

    if (sign < 0) {
        s[i++] = '-';
    }

    s[i] = '\0';

    print_string("Reverse ");
    reverse(s, i);
}

void *memcpy(void *dest, const void *src, int n)
{
	while (n) {
		n--;
		((char*)dest)[n] = ((char*)src)[n];
	}
	return dest;
}
