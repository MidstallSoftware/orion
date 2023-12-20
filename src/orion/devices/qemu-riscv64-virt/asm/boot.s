/**
 * Start code based on https://github.com/oreboot/oreboot/blob/main/src/mainboard/emulation/qemu-riscv/src/bootblock.S
 */

.section ".bootblock.boot", "ax", %progbits

.globl _boot
_boot:
	csrr a0, mhartid
spin:
	bgt a0, x0, spin

1: auipc t0, %pcrel_hi(_stack_ptr)
   lwu sp, %pcrel_lo(1b)(t0)

	li t0, 0xDEADBEEF
	sw t0, 0(sp)

	add a0, a1, x0
	call _start

forever: tail forever
cache_as_ram:
	ret
smp_pause:
	ret
trap_entry:
	ret
hls_init:
	ret
.global abort
abort: j abort

.section ".bootblock.stack", "aw", %progbits
_stack:
.space 65536

.globl _stack_ptr
.section .rodata
_stack_ptr: .word 0x80020000
