const std = @import("std");

const arches = @import("arch.zig");
const devices = @import("devices.zig");
pub const DeviceKey = std.meta.DeclEnum(devices);

pub const Arch = struct {
    name: []const u8,
    codeModel: ?std.builtin.CodeModel = null,
    assemblyFiles: ?[]const []const u8 = null,
};

pub const Device = struct {
    name: []const u8,
    cpu: std.Target.Cpu,
    codeModel: ?std.builtin.CodeModel = null,
    linker: ?[]const u8 = null,
    excludeFeatures: ?std.Target.Cpu.Feature.Set = null,
    includeFeatures: ?std.Target.Cpu.Feature.Set = null,
    assemblyFiles: ?[]const []const u8 = null,
    binaryPadding: ?u64 = null,

    pub fn arch(self: Device) Arch {
        inline for (comptime std.meta.declarations(arches)) |decl| {
            if (std.mem.eql(u8, decl.name, @tagName(self.cpu.arch))) {
                const impl = @field(arches, decl.name);
                return .{
                    .name = decl.name,
                    .codeModel = if (@hasDecl(impl, "codeModel")) impl.codeModel else null,
                    .assemblyFiles = if (@hasDecl(impl, "assemblyFiles")) impl.assemblyFiles else null,
                };
            }
        }
        unreachable;
    }

    pub fn target(self: Device) std.Target {
        return .{
            .cpu = self.cpu,
            .os = .{
                .tag = .freestanding,
                .version_range = .{ .none = {} },
            },
            .abi = std.Target.Abi.default(self.cpu.arch, .{
                .tag = .freestanding,
                .version_range = .{ .none = {} },
            }),
            .ofmt = .elf,
        };
    }

    pub inline fn crossTarget(self: Device) std.zig.CrossTarget {
        var xtarget = std.zig.CrossTarget.fromTarget(self.target());
        if (self.excludeFeatures) |excludeFeatures| {
            xtarget.cpu_features_sub = excludeFeatures;
        }

        if (self.includeFeatures) |includeFeatures| {
            xtarget.cpu_features_add = includeFeatures;
        }
        return xtarget;
    }
};

pub fn standardDeviceOption(b: *std.Build) Device {
    const deviceKey = b.option(DeviceKey, "device", "The device to build Orion for") orelse .@"qemu-riscv64-virt";

    inline for (comptime std.meta.declarations(devices)) |decl| {
        if (std.mem.eql(u8, decl.name, @tagName(deviceKey))) {
            const device = @field(devices, decl.name);
            return .{
                .name = decl.name,
                .cpu = device.cpu,
                .codeModel = if (@hasDecl(device, "codeModel")) device.codeModel else null,
                .linker = if (@hasDecl(device, "linker")) b.pathFromRoot(b.pathJoin(&.{
                    "src/orion/devices",
                    decl.name,
                    device.linker,
                })) else null,
                .excludeFeatures = if (@hasDecl(device, "excludeFeatures")) device.excludeFeatures else null,
                .includeFeatures = if (@hasDecl(device, "includeFeatures")) device.includeFeatures else null,
                .assemblyFiles = if (@hasDecl(device, "assemblyFiles")) device.assemblyFiles else null,
                .binaryPadding = if (@hasDecl(device, "binaryPadding")) device.binaryPadding else null,
            };
        }
    }

    unreachable;
}
