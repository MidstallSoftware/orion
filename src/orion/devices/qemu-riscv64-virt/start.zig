const std = @import("std");
const arch = @import("root").arch;
const fio = @import("fio");
const dtb = @import("../../dtb.zig");
const FwCfg = @import("../../drivers/fw-cfg.zig");
const phantom = @import("phantom");
const vizops = @import("vizops");
const log = std.log.scoped(.start);

const firmware_start: usize = 0x80000000;
const firmware_end: usize = firmware_start + (20 * 1024 * 1024);

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
    const alloc = fba.allocator();

    std.log.info("Memory: {} free, {} used, {} total (start: 0x{x})", .{
        std.fmt.fmtIntSizeDec(memFree),
        std.fmt.fmtIntSizeDec(firmwareSize),
        std.fmt.fmtIntSizeDec(memInfo.size),
        @intFromPtr(fba.buffer.ptr),
    });

    const fwcfg = FwCfg.init(std.mem.readInt(u64, (fdt.find("fw-cfg@", "reg") catch @panic("Coult not locate fw-cfg"))[0..8], .big)) catch |e| std.debug.panic("Failed to initialize fw-cfg: {s}", .{@errorName(e)});

    if (fwcfg.accessFile("etc/ramfb") catch null) |ramfb| {
        std.log.debug("Found ramfb: {}", .{ramfb});

        const fourcc = vizops.color.fourcc.formats.xrgb8888;

        if (ramfb.file.size != @sizeOf(Ramfb)) {
            std.debug.panic("Ramfb size mismatch (file: {}, struct: {})", .{ ramfb.file.size, @sizeOf(Ramfb) });
        }

        const fb = phantom.painting.fb.AllocatedFrameBuffer.create(alloc, .{
            .res = .{ .value = .{ 1024, 768 } },
            .colorspace = .sRGB,
            .colorFormat = vizops.color.fourcc.Value.decode(fourcc) catch |e| std.debug.panic("Failed to decode fourcc: {s}", .{@errorName(e)}),
        }) catch |e| std.debug.panic("Failed to create framebuffer: {s}", .{@errorName(e)});
        defer fb.deinit();

        var ramfbConfig = Ramfb{
            .addr = std.mem.nativeTo(u64, @intFromPtr(fb.addr() catch |e| std.debug.panic("Failed to get the fb address: {s}", .{@errorName(e)})), .big),
            .fourcc = std.mem.nativeTo(u32, fourcc, .big),
            .flags = std.mem.nativeTo(u32, 0, .big),
            .width = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0]), .big),
            .height = std.mem.nativeTo(u32, @intCast(fb.info().res.value[1]), .big),
            .stride = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0] * @divExact(fb.info().colorFormat.width(), 8)), .big),
        };

        ramfb.write(std.mem.asBytes(&ramfbConfig)) catch |e| std.debug.panic("Failed to write the ramfb config: {s}", .{@errorName(e)});
        ramfbConfig.addr = 0;
        ramfb.read(std.mem.asBytes(&ramfbConfig)) catch |e| std.debug.panic("Failed to read the ramfb config: {s}", .{@errorName(e)});

        std.log.debug("Initialized ramfb: {}", .{Ramfb{
            .addr = std.mem.toNative(u64, ramfbConfig.addr, .big),
            .fourcc = std.mem.toNative(u32, ramfbConfig.fourcc, .big),
            .flags = std.mem.toNative(u32, ramfbConfig.flags, .big),
            .width = std.mem.toNative(u32, ramfbConfig.width, .big),
            .height = std.mem.toNative(u32, ramfbConfig.height, .big),
            .stride = std.mem.toNative(u32, ramfbConfig.stride, .big),
        }});

        const scene = phantom.scene.createBackend(.fb, .{
            .allocator = alloc,
            .frame_info = phantom.scene.Node.FrameInfo.init(.{
                .res = fb.info().res,
                .colorFormat = fb.info().colorFormat,
            }),
            .target = .{ .fb = fb },
        }) catch |e| std.debug.panic("Failed to create scene: {s}", .{@errorName(e)});
        defer scene.deinit();

        std.log.debug("Created Phantom UI scene: {}", .{scene});

        const format = phantom.painting.image.formats.zigimg.create(alloc) catch |e| @panic(@errorName(e));
        defer format.deinit();

        std.log.debug("Created Phantom UI image format: {}", .{format});

        const image = format.readBuffer(@embedFile("example.gif")) catch |e| @panic(@errorName(e));
        defer image.deinit();

        std.log.debug("Created Phantom UI image: {}", .{image});

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
