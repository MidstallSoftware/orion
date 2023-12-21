const std = @import("std");
const arch = @import("root").arch;

pub fn setTimer(when: u64) void {
    const hart = arch.misc.hartId();
    const ptr: *volatile u64 = @ptrFromInt(0x2004000 + 8 * hart);
    ptr.* = when;
}
