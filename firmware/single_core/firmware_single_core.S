.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*2048)
addi sp, sp, %lo(4*2048)

/* call main */
jal ra, main

/* break */
ebreak
