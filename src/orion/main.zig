const std = @import("std");
const dtb = @import("dtb.zig");
const FwCfg = @import("drivers/fw-cfg.zig");
const uefi = @import("uefi.zig");
const phantom = @import("phantom");
const vizops = @import("vizops");

const Ramfb = extern struct {
    addr: u64 align(1),
    fourcc: u32 align(1),
    flags: u32 align(1),
    width: u32 align(1),
    height: u32 align(1),
    stride: u32 align(1),
};

pub const Options = struct {
    allocator: std.mem.Allocator,
    fdt: *dtb.Header,
    fwcfg: ?FwCfg,
};

pub fn main(options: Options) !void {
    try uefi.init(options.allocator);

    if (options.fwcfg) |fwcfg| {
        if (fwcfg.accessFile("etc/ramfb") catch null) |ramfb| {
            std.log.debug("Found ramfb: {}", .{ramfb});

            if (ramfb.file.size != @sizeOf(Ramfb)) {
                std.debug.panic("Ramfb size mismatch (file: {}, struct: {})", .{ ramfb.file.size, @sizeOf(Ramfb) });
            }

            const fb = try phantom.painting.fb.AllocatedFrameBuffer.create(options.allocator, .{
                .res = .{ .value = .{ 1024, 768 } },
                .colorspace = .sRGB,
                .colorFormat = try vizops.color.fourcc.Value.decode(vizops.color.fourcc.formats.bgrx8888),
            });
            defer fb.deinit();

            var ramfbConfig = Ramfb{
                .addr = std.mem.nativeTo(u64, @intFromPtr(try fb.addr()), .big),
                .fourcc = std.mem.nativeTo(u32, vizops.color.fourcc.formats.xrgb8888, .big),
                .flags = std.mem.nativeTo(u32, 0, .big),
                .width = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0]), .big),
                .height = std.mem.nativeTo(u32, @intCast(fb.info().res.value[1]), .big),
                .stride = std.mem.nativeTo(u32, @intCast(fb.info().res.value[0] * @divExact(fb.info().colorFormat.width(), 8)), .big),
            };

            try ramfb.write(std.mem.asBytes(&ramfbConfig));
            ramfbConfig.addr = 0;
            try ramfb.read(std.mem.asBytes(&ramfbConfig));

            std.log.debug("Initialized ramfb: {}", .{Ramfb{
                .addr = std.mem.toNative(u64, ramfbConfig.addr, .big),
                .fourcc = std.mem.toNative(u32, ramfbConfig.fourcc, .big),
                .flags = std.mem.toNative(u32, ramfbConfig.flags, .big),
                .width = std.mem.toNative(u32, ramfbConfig.width, .big),
                .height = std.mem.toNative(u32, ramfbConfig.height, .big),
                .stride = std.mem.toNative(u32, ramfbConfig.stride, .big),
            }});

            const scene = try phantom.scene.createBackend(.fb, .{
                .allocator = options.allocator,
                .frame_info = phantom.scene.Node.FrameInfo.init(.{
                    .res = fb.info().res,
                    .colorFormat = fb.info().colorFormat,
                }),
                .target = .{ .fb = fb },
            });
            defer scene.deinit();

            std.log.debug("Created Phantom UI scene: {}", .{scene});

            const format = try phantom.painting.image.formats.zigimg.create(options.allocator);
            defer format.deinit();

            std.log.debug("Created Phantom UI image format: {}", .{format});

            const image = try format.readBuffer(@embedFile("example.gif"));
            defer image.deinit();

            std.log.debug("Created Phantom UI image: {}", .{image});

            const fbNode = try scene.createNode(.NodeFrameBuffer, .{
                .source = try image.buffer(0),
            });

            while (true) {
                _ = try scene.frame(fbNode);

                try fbNode.setProperties(.{
                    .source = try image.buffer(scene.seq % image.info().seqCount),
                });
            }
        }
    }
}
