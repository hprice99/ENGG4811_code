#include "io.h"
#include "print.h"
#include "matrix.h"

#define LOOP_COUNTER 1000000000

#define MAX_ENTRY 10

// https://man7.org/linux/man-pages/man3/rand.3.html
static unsigned long next = 1;

/* RAND_MAX assumed to be 32767 */
int myrand(void) {
    next = next * 1103515245 + 12345;
    return((unsigned)(next/65536) % MAX_ENTRY);
}

void mysrand(unsigned int seed) {
    next = seed;
}

void main()
{
    int ledValue = 0;

    int switchValue = 0;

    int i = 0;

    LED = ledValue;

    multiply_matrices();

    print_string("Matrix multiplication completed\n");

    while (1) {

        LED = ledValue;
        switchValue = SWITCH;
        ledValue = switchValue;
    }
}
