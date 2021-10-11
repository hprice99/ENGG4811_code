.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*32678)
addi sp, sp, %lo(4*32678)

/* call main */
jal ra, main

/* break */
ebreak
