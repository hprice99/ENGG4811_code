#define CHAR_OUTPUT (*(volatile char*)0x10000000)
#define LED (*(volatile char*)0x20000000)
#define SWITCH (*(volatile char*)0x30000000)

#define MATRIX_ROW_END (*(volatile char*)0x50000000)
#define MATRIX_END (*(volatile char*)0x60000000)
#define MATRIX_POSITION (*(volatile char*)0x70000000)
#define MATRIX_OUTPUT (*(volatile long*)0x80000000)

#define LOOP_COUNTER 1000000000

#define MATRIX_SIZE 64

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

void print_char(char c)
{
    CHAR_OUTPUT = c;
}

void print_string(const char *s)
{
	while (*s) print_char(*s++);
}

void *memcpy(void *dest, const void *src, int n)
{
	while (n) {
		n--;
		((char*)dest)[n] = ((char*)src)[n];
	}
	return dest;
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

void print_matrix(long* matrix, int rows, int cols) {

    char digit[7];

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            print_string("itoa ");
            itoa(*((matrix + row * rows) + col), digit);

            print_string("Print ");
            print_string(digit);
        }
        print_string(" ; \n");
    }
}

void output_digit(long digit) {

    MATRIX_OUTPUT = digit;
}

void output_matrix(char* label, long* matrix, int rows, int cols) {

    print_string(label);
    print_string(" = [ \n");

    for (long row = 0; row < rows; row++) {
        for (long col = 0; col < cols; col++) {
            
            output_digit(*((matrix + row * rows) + col));
        }
        MATRIX_ROW_END = 1;
    }

    MATRIX_END = 1;

    print_string("] \n\n");
}

void multiply_matrices(void) {

    // Create matrices
    long A[MATRIX_SIZE][MATRIX_SIZE];
    long B[MATRIX_SIZE][MATRIX_SIZE];
    long C[MATRIX_SIZE][MATRIX_SIZE];

    // Create random matrices
    /*
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            A[row][col] = myrand();
            B[row][col] = myrand();
            C[row][col] = 0;
        }
    }
    */

    // Create fixed matrices
    for (long row = 0; row < MATRIX_SIZE; row++) {
        for (long col = 0; col < MATRIX_SIZE; col++) {
            if (row < 50) {
                A[row][col] = row + 1;
            } else {
                A[row][col] = row - 50;
            }
            
            if (col < 50) {
                B[row][col] = col + 1;
            } else {
                B[row][col] = col - 50;
            }
            
            C[row][col] = 0;
        }
    }

    // Print A and B
    output_matrix("A", (long*)A, MATRIX_SIZE, MATRIX_SIZE);
    output_matrix("B", (long*)B, MATRIX_SIZE, MATRIX_SIZE);

    for (long i = 0; i < MATRIX_SIZE; i++) {
        for (long j = 0; j < MATRIX_SIZE; j++) {
            for (long k = 0; k < MATRIX_SIZE; k++) {
                C[i][j] = C[i][j] + A[i][k] * B[k][j];
            }
        }

        MATRIX_POSITION = i;

        print_string(" Row done\n");
    }

    output_matrix("C = A*B", (long*)C, MATRIX_SIZE, MATRIX_SIZE);
}

void main()
{
    int ledValue = 0;

    int switchValue = 0;

    int i = 0;

    LED = ledValue;

    multiply_matrices();

    while (1) {

        LED = ledValue;
        switchValue = SWITCH;
        ledValue = switchValue;
    }
}
