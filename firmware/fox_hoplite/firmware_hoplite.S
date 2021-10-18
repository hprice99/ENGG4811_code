.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*3072)
addi sp, sp, %lo(4*3072)

/* call main */
jal ra, main

/* break */
ebreak
