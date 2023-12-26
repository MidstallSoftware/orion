const std = @import("std");
const dtb = @import("dtb.zig");
const uefi = @import("uefi.zig");
const fio = @import("fio");
const phantom = @import("phantom");
const vizops = @import("vizops");

pub const Options = struct {
    allocator: std.mem.Allocator,
    fdt: *dtb.Header,
    fwcfg: ?fio.FwCfg,
};

pub fn main(options: Options) !void {
    try uefi.init(options.allocator);

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
