.section .init
.global main

/* set stack pointer */
lui sp, %hi(16*4096)
addi sp, sp, %lo(16*4096)

/* call main */
jal ra, main

/* break */
ebreak
