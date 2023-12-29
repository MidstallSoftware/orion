const builtin = @import("builtin");
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

    if (@as(?[]const u8, comptime switch (builtin.cpu.arch) {
        .aarch64 => "pcie@",
        .riscv64 => "pci@",
        else => null,
    })) |pciNodePrefix| {
        if (options.fdt.find(pciNodePrefix, "reg") catch null) |pciBlob| {
            const barBlob = try options.fdt.find(pciNodePrefix, "ranges");

            const pci = try fio.pci.bus.Mmio.create(.{
                .allocator = options.allocator,
                .baseAddress = std.mem.readInt(u64, pciBlob[0..][0..8], .big),
                .size = std.mem.readInt(u64, pciBlob[8..][0..8], .big),
                .base32 = std.mem.readInt(u64, barBlob[0x28..][0..8], .big),
                .base64 = std.mem.readInt(u64, barBlob[0x3C..][0..8], .big),
            });
            defer pci.deinit();

            const devices = try pci.enumerate();
            defer devices.deinit();

            for (devices.items) |dev| {
                std.log.info("PCI device: {}", .{dev});
            }
        }
    }

    if (options.fdt.find("rtc", "compatible") catch null) |rtcKind| {
        if (std.mem.eql(u8, rtcKind[0..(rtcKind.len - 1)], "google,goldfish-rtc")) {
            var rtc = fio.rtc.init(.goldfish, .{
                .baseAddress = std.mem.readInt(u64, (try options.fdt.find("rtc", "reg"))[0..8], .big),
            });
            std.log.info("{}", .{rtc.readTime()});
        }
    }

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
