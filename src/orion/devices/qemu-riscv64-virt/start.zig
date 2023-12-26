const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const phantom = @import("phantom");
const vizops = @import("vizops");
const log = std.log.scoped(.start);

const firmware_start: usize = 0x80000000;
const firmware_end: usize = firmware_start + (20 * 1024 * 1024);

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

    std.log.info("Firmware: 0x{x} - 0x{x}", .{ firmware_start, firmware_end });

    const firmwareSize = firmware_end - firmware_start;
    const memFree = memInfo.size - firmwareSize;

    var fba = std.heap.FixedBufferAllocator.init(@as([*]u8, @ptrFromInt(firmware_end))[0..memFree]);

    std.log.info("Memory: {} free, {} used, {} total (start: 0x{x})", .{
        std.fmt.fmtIntSizeDec(memFree),
        std.fmt.fmtIntSizeDec(firmwareSize),
        std.fmt.fmtIntSizeDec(memInfo.size),
        @intFromPtr(fba.buffer.ptr),
    });

    const fwcfg = fio.FwCfg.init(std.mem.readInt(u64, (fdt.find("fw-cfg@", "reg") catch @panic("Coult not locate fw-cfg"))[0..8], .big)) catch |e| std.debug.panic("Failed to initialize fw-cfg: {s}", .{@errorName(e)});

    @import("../../main.zig").main(.{
        .allocator = fba.allocator(),
        .fdt = fdt,
        .fwcfg = fwcfg,
    }) catch |e| {
        std.debug.panicExtra(@errorReturnTrace(), @returnAddress(), "orion.main failed with {s}", .{@errorName(e)});
    };

    while (true) {}
}
