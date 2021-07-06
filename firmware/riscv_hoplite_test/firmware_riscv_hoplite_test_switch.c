#include "io.h"
#include "print.h"

void main() {
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
}
