const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const log = std.log.scoped(.start);

pub var uart: fio.uart.Base = undefined;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    _ = error_return_trace;
    uart.writer().print("PANIC: {s}\n", .{msg});
    while (true) {}
}

export fn _start(fdtPtr: usize) noreturn {
    uart = fio.uart.init(.ns16550a, .{
        .baseAddress = 0x1000_0000,
        .wordLength = .@"8",
        .stopBits = .@"1",
        .parityBit = false,
        .paritySelect = .even,
        .stickyParity = false,
        .breakSet = false,
        .dmaMode = 0,
        .divisor = 100,
    }) catch unreachable;

    arch.timer.init();
    arch.sbi.setTimer(1);
    log.info("Clock initialized", .{});

    std.log.info("Hellord", .{});
    arch.interrupt.enable();

    const fdt: *dtb.Header = @ptrFromInt(fdtPtr);
    if (!fdt.valid()) @panic("fdt is not valid");

    const cpuCount = blk: {
        var i: usize = 0;
        while (fdt.findCpuId(i) != null) : (i += 1) {}
        break :blk i;
    };

    const mem = fdt.findMemory() orelse @panic("No memory entry was present");

    std.log.info("System has {} CPU's and {} RAM", .{ cpuCount, mem.size });
    while (true) {}
}
