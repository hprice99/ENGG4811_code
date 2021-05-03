#define CHAR_OUTPUT (*(volatile char*)0x10000000)
#define LED (*(volatile char*)0x20000000)
#define SWITCH (*(volatile char*)0x30000000)

#define MATRIX_OUTPUT_FIRST_BYTE (*(volatile char*)0x40000000)
#define MATRIX_OUTPUT_SECOND_BYTE (*(volatile char*)0x40000008)
#define MATRIX_OUTPUT_THIRD_BYTE (*(volatile char*)0x40000016)
#define MATRIX_OUTPUT_FOURTH_BYTE (*(volatile char*)0x40000024)

#define MATRIX_ROW_END (*(volatile char*)0x50000000)
#define MATRIX_END (*(volatile char*)0x60000000)
#define MATRIX_POSITION (*(volatile char*)0x70000000)

#define LOOP_COUNTER 1000000000

#define MATRIX_SIZE 50

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
void itoa(int n, char s[]) {
    int i, sign;

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

void print_matrix(int* matrix, int rows, int cols) {

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

void output_digit(int digit) {

    /*
    if (digit <= 255) {
        digit = digit & 0xFF;
    } else if (digit <= 65535) {
        digit = digit & 0xFFFF;
    } else if (digit <= 16777215) {
        digit = digit & 0xFFFFFF;
    }
    */

    MATRIX_OUTPUT_FIRST_BYTE = digit & 0xFF;
    MATRIX_OUTPUT_SECOND_BYTE = (digit >> 8) & 0xFF;
    MATRIX_OUTPUT_THIRD_BYTE = (digit >> 16) & 0xFF;
    MATRIX_OUTPUT_FOURTH_BYTE = (digit >> 24) & 0xFF;
}

void output_matrix(int* matrix, int rows, int cols) {

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            
            output_digit(*((matrix + row * rows) + col));
        }
        MATRIX_ROW_END = 1;
    }

    MATRIX_END = 1;
}

void multiply_matrices(void) {
    // Create matrices
    int A[MATRIX_SIZE][MATRIX_SIZE];
    int B[MATRIX_SIZE][MATRIX_SIZE];
    int C[MATRIX_SIZE][MATRIX_SIZE];

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
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            A[row][col] = row + 1;
            B[row][col] = col + 1;
            C[row][col] = 0;
        }

        MATRIX_POSITION = row;

        // print_string("Row done ");

        /*
        char message[200];
        itoa(row, message);
        print_string(message);
        */

        // print_string("\n");
    }
    MATRIX_END = 1;

    // Print A and B
    /*
    print_string("A = ");
    print_matrix((int*)A, MATRIX_SIZE, MATRIX_SIZE);

    print_string("B = ");
    print_matrix((int*)B, MATRIX_SIZE, MATRIX_SIZE);
    */

    // print_string("A and B created\n");

    output_matrix((int*)A, MATRIX_SIZE, MATRIX_SIZE);
    output_matrix((int*)B, MATRIX_SIZE, MATRIX_SIZE);

    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            for (int k = 0; k < MATRIX_SIZE; k++) {
                C[i][j] = C[i][j] + A[i][k] * B[k][j];
            }
        }

        MATRIX_POSITION = i;
    }

    /*
    print_string("C = ");
    print_matrix((int*)C, MATRIX_SIZE, MATRIX_SIZE);
    */

    output_matrix((int*)C, MATRIX_SIZE, MATRIX_SIZE);
}

void main()
{
    int ledValue = 0;

    int switchValue = 0;

    int i = 0;

    LED = ledValue;

    print_string("ENGG4811 PicoRV32 test\n");

	char message[] = "$Uryyb+Jbeyq!+Vs+lbh+pna+ernq+guvf+zrffntr+gura$gur+CvpbEI32+PCH"
			"+frrzf+gb+or+jbexvat+whfg+svar.$$++++++++++++++++GRFG+CNFFRQ!$$";
	for (int i = 0; message[i]; i++)
		switch (message[i])
		{
		case 'a' ... 'm':
		case 'A' ... 'M':
			message[i] += 13;
			break;
		case 'n' ... 'z':
		case 'N' ... 'Z':
			message[i] -= 13;
			break;
		case '$':
			message[i] = '\n';
			break;
		case '+':
			message[i] = ' ';
			break;
		}
	print_string(message);

    multiply_matrices();

    while (1) {

        LED = ledValue;

        /*
        if (ledValue) {
            print_string("LED on\n");
        } else {
            print_string("LED off\n");
        }
        */

        /*
        while (i < LOOP_COUNTER) {

            i++;
        }
        
        i = 0;
        */

        switchValue = SWITCH;

        if (switchValue) {
            // print_string("Switch on\n");
            // ledValue = 1 - ledValue;

            ledValue = 1;
        } else {
            // print_string("Switch off\n");

            ledValue = 0;
        }
    }
}
