.section .init
.global main

/* set stack pointer */
lui sp, %hi(16*2048)
addi sp, sp, %lo(16*2048)

/* call main */
jal ra, main

/* break */
ebreak
