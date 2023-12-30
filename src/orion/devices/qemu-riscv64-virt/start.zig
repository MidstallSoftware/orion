const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtree = @import("dtree");
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

    const dtb = dtree.Reader.initBuffer(@as([*]const u8, @ptrFromInt(fdtPtr))[0..0x10000]) catch |e| std.debug.panic("Could not load the fdt: {s}", .{@errorName(e)});

    const cpuCount = blk: {
        var i: usize = 0;
        while (true) : (i += 1) {
            var buf = [_]u8{0} ** 32;
            _ = std.fmt.bufPrint(&buf, "cpu@{}", .{i}) catch break;

            const len = blk2: {
                var x: usize = 0;
                while (buf[x] != 0) : (x += 1) {}
                break :blk2 x;
            };

            if (dtb.findLoose(&.{ "", "cpus", buf[0..len], "reg" }) catch null) |_| continue;
            break;
        }
        break :blk i;
    };

    const memInfo = dtb.findLoose(&.{ "", "memory@", "reg" }) catch |e| std.debug.panic("Could not find the memory info: {s}", .{@errorName(e)});
    const memSize = std.mem.readInt(u64, memInfo[8..16], .big);

    std.log.info("System has {} CPU{s}", .{
        cpuCount,
        if (cpuCount > 1) "'s" else "",
    });

    std.log.info("Firmware: 0x{x} - 0x{x}", .{ firmware_start, firmware_end });

    const firmwareSize = firmware_end - firmware_start;
    const memFree = memSize - firmwareSize;

    var fba = std.heap.FixedBufferAllocator.init(@as([*]u8, @ptrFromInt(firmware_end))[0..memFree]);

    std.log.info("Memory: {} free, {} used, {} total (start: 0x{x})", .{
        std.fmt.fmtIntSizeDec(memFree),
        std.fmt.fmtIntSizeDec(firmwareSize),
        std.fmt.fmtIntSizeDec(memSize),
        @intFromPtr(fba.buffer.ptr),
    });

    const fwcfg = fio.FwCfg.init(std.mem.readInt(u64, (dtb.findLoose(&.{ "", "fw-cfg@", "reg" }) catch @panic("Coult not locate fw-cfg"))[0..8], .big)) catch |e| std.debug.panic("Failed to initialize fw-cfg: {s}", .{@errorName(e)});

    @import("../../main.zig").main(.{
        .allocator = fba.allocator(),
        .dtb = dtb,
        .fwcfg = fwcfg,
    }) catch |e| {
        std.debug.panicExtra(@errorReturnTrace(), @returnAddress(), "orion.main failed with {s}", .{@errorName(e)});
    };

    while (true) {}
}
