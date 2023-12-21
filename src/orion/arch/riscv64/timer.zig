const std = @import("std");
const builtin = @import("builtin");
const Register = @import("cpu.zig").Register;

pub fn init() void {
    Register.mip.clr(1 << 5 | 1 << 1);
    Register.mie.set(1 << 7 | 1 << 5 | 1 << 1);

    if (Register.misa.r() & (1 << ('S' - 'A')) != 0) {
        Register.mideleg.set(0x20);
    }

    Register.mcounteren.w(7);

    Register.mstatus.clr(0x1800);
    Register.mstatus.set(0x802);
}
