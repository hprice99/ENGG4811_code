.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*4096)
addi sp, sp, %lo(4*4096)

/* call main */
jal ra, main

/* break */
ebreak
