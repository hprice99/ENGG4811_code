.section .init
.global main

/* set stack pointer */
lui sp, %hi(16*8192)
addi sp, sp, %lo(16*8192)

/* call main */
jal ra, main

/* break */
ebreak
