.section .init
.global main

/* set stack pointer */
lui sp, %hi(4*{{ firmware.memSize }})
addi sp, sp, %lo(4*{{ firmware.memSize }})

/* call main */
jal ra, main

/* break */
ebreak
