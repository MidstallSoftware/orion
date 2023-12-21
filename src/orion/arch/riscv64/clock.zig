const std = @import("std");
const misc = @import("misc.zig");
const sbi = @import("sbi.zig");
const Register = @import("reg.zig").Register;

pub var tick: u64 = 0;

pub fn enable() void {
    var sie = Register.sie.r();
    sie |= (1 << 5);
    Register.sie.w(sie);
}

pub fn handle() void {
    tick += 1;
    std.log.info("Tick {}", .{tick});
    sbi.setTimer(misc.getTime() + @as(usize, 1e7 / 100));
}
