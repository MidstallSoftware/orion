const std = @import("std");
const cpu = @import("cpu.zig");
const sbi = @import("sbi.zig");

pub var tick: u64 = 0;

pub fn enable() void {
    var sie = cpu.Register.sie.r();
    sie |= (1 << 5);
    cpu.Register.sie.w(sie);
}

pub fn handle() void {
    tick += 1;
    std.log.info("Tick {}", .{tick});
    sbi.setTimer(cpu.getTime() + @as(usize, 1e7 / 100));
}
