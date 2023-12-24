const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const FwCfg = @import("../../drivers/fw-cfg.zig");
const phantom = @import("phantom");
const vizops = @import("vizops");
const log = std.log.scoped(.start);

pub var uart: fio.uart.Base = undefined;

const Ramfb = extern struct {
    addr: u64 align(1),
    fourcc: u32 align(1),
    flags: u32 align(1),
    width: u32 align(1),
    height: u32 align(1),
    stride: u32 align(1),
};

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

    const firmwareStart: usize = 0x80000000;
    const firmwareSize: usize = 0x200000;
    const firmwareEnd = firmwareStart + firmwareSize;

    const memFree = memInfo.size - firmwareSize;
    std.log.info("Memory: {} free, {} used, {} total", .{
        memFree,
        firmwareSize,
        memInfo.size,
    });

    var fba = std.heap.FixedBufferAllocator.init(@as([*]u8, @ptrFromInt(firmwareEnd))[0..memFree]);
    const alloc = fba.allocator();

    const fwcfg = FwCfg.init(std.mem.readInt(u64, (fdt.find("fw-cfg@", "reg") catch @panic("Coult not locate fw-cfg"))[0..8], .big)) catch |e| std.debug.panic("Failed to initialize fw-cfg: {s}", .{@errorName(e)});

    if (fwcfg.accessFile("etc/ramfb") catch null) |ramfb| {
        std.log.info("Found ramfb: {}", .{ramfb});

        if (ramfb.file.size != @sizeOf(Ramfb)) {
            std.debug.panic("Ramfb size mismatch (file: {}, struct: {})", .{ ramfb.file.size, @sizeOf(Ramfb) });
        }

        const fb = phantom.painting.fb.AllocatedFrameBuffer.create(alloc, .{
            .res = .{ .value = .{ 1024, 768 } },
            .colorspace = .sRGB,
            .colorFormat = .{ .rgb = @splat(8) },
        }) catch |e| std.debug.panic("Failed to create framebuffer: {s}", .{@errorName(e)});
        defer fb.deinit();

        var ramfbConfig = Ramfb{
            .addr = std.mem.nativeTo(u64, @intFromPtr(fb.addr() catch |e| std.debug.panic("Failed to get the fb address: {s}", .{@errorName(e)})), .big),
            .fourcc = std.mem.nativeTo(u32, vizops.color.fourcc.formats.xrgb8888, .big),
            .flags = std.mem.nativeTo(u32, 0, .big),
            .width = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0]), .big),
            .height = std.mem.nativeTo(u32, @intCast(fb.info().res.value[1]), .big),
            .stride = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0] * 4 * fb.info().res.value[1]), .big),
        };

        ramfb.write(std.mem.asBytes(&ramfbConfig)) catch |e| std.debug.panic("Failed to write the ramfb config: {s}", .{@errorName(e)});

        const scene = phantom.scene.createBackend(.fb, .{
            .allocator = alloc,
            .frame_info = phantom.scene.Node.FrameInfo.init(.{
                .res = fb.info().res,
                .colorFormat = fb.info().colorFormat,
            }),
            .target = .{ .fb = fb },
        }) catch |e| std.debug.panic("Failed to create scene: {s}", .{@errorName(e)});
        defer scene.deinit();

        const format = phantom.painting.image.formats.zigimg.create(alloc) catch |e| @panic(@errorName(e));
        defer format.deinit();

        const image = format.readBuffer(@embedFile("example.gif")) catch |e| @panic(@errorName(e));
        defer image.deinit();

        const fbNode = scene.createNode(.NodeFrameBuffer, .{
            .source = image.buffer(0) catch |e| @panic(@errorName(e)),
        }) catch |e| @panic(@errorName(e));

        var prevTime = arch.cpu.getTime();
        while (true) {
            const currTime = arch.cpu.getTime();
            const deltaTime = currTime - prevTime;

            std.log.info("Frame delta: {} ({} -> {})", .{ deltaTime, prevTime, currTime });

            _ = scene.frame(fbNode) catch |e| @panic(@errorName(e));

            fbNode.setProperties(.{
                .source = image.buffer(scene.seq % image.info().seqCount) catch |e| @panic(@errorName(e)),
            }) catch |e| @panic(@errorName(e));

            prevTime = currTime;
        }
    }
    while (true) {}
}
