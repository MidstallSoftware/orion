const std = @import("std");
const builtin = @import("builtin");
const Register = @import("cpu.zig").Register;

pub fn init() void {
    Register.mstatus.clr(1 << 5 | 1 << 1);
    Register.mie.set(1 << 7 | 1 << 5 | 1 << 1);

    if (Register.misa.r() & (1 << ('S' - 'A')) != 0) {
        Register.mideleg.set(1 << 5 | 1 << 1);
        Register.mideleg.set(0 | 1 << 0 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 0xa | 1 << 0xb | 1 << 0xc | 1 << 0xd | 1 << 0xf);
    }

    Register.mcounteren.w(7);
}
