const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const FwCfg = @import("../../drivers/fw-cfg.zig");
const log = std.log.scoped(.start);

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

    const firmwareSize: usize = 0x200000;
    const memFree = memInfo.size - firmwareSize;
    std.log.info("Memory: {} free, {} used, {} total", .{
        memFree,
        firmwareSize,
        memInfo.size,
    });

    const fwcfg = FwCfg.init(std.mem.readInt(u64, (fdt.find("fw-cfg@", "reg") catch @panic("Coult not locate fw-cfg"))[0..8], .big)) catch |e| std.debug.panic("Failed to initialize fw-cfg: {s}", .{ @errorName(e) });

    var iter = fwcfg.fileIterator() catch |e| std.debug.panic("Failed to access fw-cfg files: {s}", .{ @errorName(e) });

    while (iter.next() catch |e| std.debug.panic("Failed to iterate files: {s}", .{ @errorName(e) })) |file| {
        std.log.info("{}", .{ file });
    }
    while (true) {}
}
