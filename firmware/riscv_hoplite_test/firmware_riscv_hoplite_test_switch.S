.section .init
.global main

/* set stack pointer */
lui sp, %hi(16*256)
addi sp, sp, %lo(16*256)

/* call main */
jal ra, main

/* break */
ebreak
