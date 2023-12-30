const builtin = @import("builtin");
const std = @import("std");
const uefi = @import("uefi.zig");
const fio = @import("fio");
const dtree = @import("dtree");
const phantom = @import("phantom");
const vizops = @import("vizops");

pub const Options = struct {
    allocator: std.mem.Allocator,
    dtb: ?dtree.Reader,
    fwcfg: ?fio.FwCfg,
};

pub fn main(options: Options) !void {
    try uefi.init(options.allocator);

    const devMan = try fio.DeviceManager.create(.{
        .allocator = options.allocator,
        .dtb = options.dtb,
    });
    defer devMan.deinit();

    const list = try devMan.enumerateDeviceTree();
    defer list.deinit();

    for (list.items) |e| std.log.info("Found {}", .{e});

    if (options.fwcfg) |fwcfg| {
        if (fwcfg.accessFile("etc/ramfb") catch null) |_| {
            const surface = try phantom.display.backends.ramfb.Surface.new(options.allocator, .{
                .fwcfg = fwcfg,
                .res = .{ .value = .{ 1024, 768 } },
                .fourcc = vizops.color.fourcc.formats.xrgb8888,
            });
            errdefer surface.deinit();

            const scene = try surface.createScene(.fb);

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
