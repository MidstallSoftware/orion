const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const log = std.log.scoped(.start);
const firmwareSize = @import("root").device.binaryPadding;

pub var uart: fio.uart.Base = undefined;

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
    arch.interrupt.enable();
    log.info("Clock initialized", .{});

    const fdt: *dtb.Header = @ptrFromInt(fdtPtr);
    if (!fdt.valid()) @panic("fdt is not valid");

    const cpuCount = blk: {
        var i: usize = 0;
        while (fdt.findCpuId(i) != null) : (i += 1) {}
        break :blk i;
    };

    const memInfo = fdt.findMemory() orelse @panic("No memory entry was present");

    std.log.info("System has {} CPU{s}", .{
        cpuCount,
        if (cpuCount > 1) "'s" else "",
    });

    const memFree = memInfo.size - firmwareSize;
    std.log.info("Memory: {} free, {} used, {} total", .{
        memFree,
        firmwareSize,
        memInfo.size,
    });
    while (true) {}
}
