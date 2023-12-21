const std = @import("std");
const cpu = @import("cpu.zig");
const device = @import("root").device;

pub fn sendIpi(pmask: ?*usize, t: isize) void {
    var mask = cpu.mprv.readUsize(pmask);
    var i: usize = 0;
    while (i < mask) : (i += 1) {
        if (mask & 1 != 0) {
            cpu.list[i].ipiPending |= t;
            device.timer.setMsip(i, 1);
        }
        mask = mask >> 1;
    }
}

pub fn setTimer(time: u64) void {
    cpu.Register.mip.clr(1 << 5);
    cpu.Register.mie.set(1 << 7);
    device.timer.setTimer(time);
}
