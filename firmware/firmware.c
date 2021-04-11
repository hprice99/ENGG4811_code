#define CHAR_OUTPUT (*(volatile char*)0x10000000)
#define LED (*(volatile char*)0x20000000)
#define SWITCH (*(volatile char*)0x30000000)

#define LOOP_COUNTER 10

void putc(char c)
{
	CHAR_OUTPUT = c;
}

void puts(const char *s)
{
	while (*s) putc(*s++);
}

void *memcpy(void *dest, const void *src, int n)
{
	while (n) {
		n--;
		((char*)dest)[n] = ((char*)src)[n];
	}
	return dest;
}

void main()
{
    int ledValue = 0;

    int switchValue = 0;

    LED = ledValue;

    puts("ENGG4811 PicoRV32 test\n");

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
	puts(message);

    while (1) {

        LED = ledValue;

        if (ledValue) {
            puts("LED on\n");
        } else {
            puts("LED off\n");
        }

        for (int i = 0; i < LOOP_COUNTER; i++) {

        }

        switchValue = SWITCH;

        if (switchValue) {
            puts("Switch on\n");
        } else {
            puts("Switch off\n");
        }

        ledValue = 1 - ledValue;
    }
}
