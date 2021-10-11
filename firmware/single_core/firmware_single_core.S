.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*32768)
addi sp, sp, %lo(4*32768)

/* call main */
jal ra, main

/* break */
ebreak
