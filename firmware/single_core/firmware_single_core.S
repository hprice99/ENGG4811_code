.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*16384)
addi sp, sp, %lo(4*16384)

/* call main */
jal ra, main

/* break */
ebreak
