const std = @import("std");
const arch = @import("root").arch;

pub fn setTimer(when: u64) void {
    const hart = arch.cpu.hartId();
    const ptr: *volatile u64 = @ptrFromInt(0x2004000 + 8 * hart);
    ptr.* = when;
}

pub fn setMsip(hart: usize, val: usize) void {
    const ptr: *volatile u32 = @ptrFromInt(0x2000000 + 4 * hart);
    ptr.* = if (val > 0) 1 else 0;
}
