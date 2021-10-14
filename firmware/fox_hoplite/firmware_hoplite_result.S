.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*5120)
addi sp, sp, %lo(4*5120)

/* call main */
jal ra, main

/* break */
ebreak
