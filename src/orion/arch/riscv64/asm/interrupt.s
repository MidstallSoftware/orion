.globl trap_entry
.align 2
trap_entry:
  addi sp, sp, -8 * 34
  sd x1, 0(sp)
  sd x2, 1 * 8(sp) // sp - 8 * 34 
  sd x3, 2 * 8(sp)
  sd x4, 3 * 8(sp)
  sd x5, 4 * 8(sp)
  sd x6, 5 * 8(sp)
  sd x7, 6 * 8(sp)
  sd x10, 9 * 8(sp)
  sd x11, 10 * 8(sp)
  sd x12, 11 * 8(sp)
  sd x13, 12 * 8(sp)
  sd x14, 13 * 8(sp)
  sd x15, 14 * 8(sp)
  sd x16, 15 * 8(sp)
  sd x17, 16 * 8(sp)
  sd x28, 27 * 8(sp)
  sd x29, 28 * 8(sp)
  sd x30, 29 * 8(sp)
  sd x31, 30 * 8(sp)

  csrr s1, mstatus
  csrr s2, mepc
  sd s1, 32 * 8(sp)
  sd s2, 33 * 8(sp)

  mv a0, sp
  csrr a1, mcause
  csrr a2, mtval

  jal trap_handler

  ld s1, 32 * 8(sp)
  ld s2, 33 * 8(sp)
  csrw mstatus, s1
  csrw mepc, s2

  ld x1, 0(sp)
  ld x3, 2 * 8(sp)
  // ld x4, 3 * 8(sp) // do not load tp
  ld x5, 4 * 8(sp)
  ld x6, 5 * 8(sp)
  ld x7, 6 * 8(sp)
  ld x10, 9 * 8(sp)
  ld x11, 10 * 8(sp)
  ld x12, 11 * 8(sp)
  ld x13, 12 * 8(sp)
  ld x14, 13 * 8(sp)
  ld x15, 14 * 8(sp)
  ld x16, 15 * 8(sp)
  ld x17, 16 * 8(sp)
  ld x28, 27 * 8(sp)
  ld x29, 28 * 8(sp)
  ld x30, 29 * 8(sp)
  ld x31, 30 * 8(sp)
  ld sp, 1 * 8(sp)
  addi sp, sp, 8 * 34
  mret
