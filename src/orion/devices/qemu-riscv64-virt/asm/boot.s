/**
 * Start code based on https://github.com/oreboot/oreboot/blob/main/src/mainboard/emulation/qemu-riscv/src/bootblock.S
 */

.section ".bootblock.boot", "ax", %progbits

.globl _boot
_boot:
	csrr a0, mhartid
spin:
	bgt a0, x0, spin

1:
  la t0, _stack
  slli t1, a0, 12
  add t0, t0, t1
	li t1, 0xDEADBEEF
	sw t1, 0(t0)
  li t1, 65536
  add sp, t0, t1

  la t0, trap_entry
  csrw mtvec, t0
  csrwi mip, 0

	add a0, a1, x0
	call _start

forever: tail forever
.global abort
abort: j abort

.section ".bootblock.stack", "aw", %progbits
_stack:
.space 65536
