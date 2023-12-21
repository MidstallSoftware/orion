const std = @import("std");
const Register = @import("reg.zig").Register;
const device = @import("root").device;

pub fn setTimer(time: u64) void {
    Register.mip.clr(1 << 5);
    Register.mie.set(1 << 7);
    device.timer.setTimer(time);
}
