const std = @import("std");

const devices = @import("src/orion/devices.zig");
const DeviceKey = std.meta.DeclEnum(devices);

const Device = struct {
    name: []const u8,
    cpu: std.Target.Cpu,
    codeModel: ?std.builtin.CodeModel = null,
    linker: ?[]const u8 = null,
    excludeFeatures: ?std.Target.Cpu.Feature.Set = null,
    assemblyFiles: ?[]const []const u8 = null,
    binaryPadding: ?u64 = null,

    pub fn target(self: Device) std.Target {
        return .{
            .cpu = self.cpu,
            .os = .{
                .tag = .freestanding,
                .version_range = .{ .none = {} },
            },
            .abi = .none,
            .ofmt = .elf,
        };
    }

    pub inline fn crossTarget(self: Device) std.zig.CrossTarget {
        var xtarget = std.zig.CrossTarget.fromTarget(self.target());
        if (self.excludeFeatures) |excludeFeatures| {
            xtarget.cpu_features_sub = excludeFeatures;
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
                .assemblyFiles = if (@hasDecl(device, "assemblyFiles")) device.assemblyFiles else null,
                .binaryPadding = if (@hasDecl(device, "binaryPadding")) device.binaryPadding else null,
            };
        }
    }

    unreachable;
}

pub fn build(b: *std.Build) void {
    const device = standardDeviceOption(b);
    const optimize = b.standardOptimizeOption(.{});

    const fio = b.dependency("fio", .{
        .target = device.crossTarget(),
        .optimize = optimize,
    });

    const options = b.addOptions();
    options.addOption([]const u8, "device", device.name);

    const exe = b.addExecutable(.{
        .name = "orion",
        .root_source_file = .{ .path = b.pathFromRoot("src/orion.zig") },
        .target = device.crossTarget(),
        .optimize = optimize,
        .linkage = .static,
    });

    exe.addModule("options", options.createModule());
    exe.addModule("fio", fio.module("fio"));

    if (device.linker) |linkerPath| {
        exe.linker_script = .{ .path = linkerPath };
    }

    if (device.codeModel) |codeModel| {
        exe.code_model = codeModel;
    }

    if (device.assemblyFiles) |assemblyFiles| {
        for (assemblyFiles) |file| {
            exe.addAssemblyFile(.{
                .path = b.pathFromRoot(b.pathJoin(&.{
                    "src/orion/devices",
                    device.name,
                    file,
                })),
            });
        }
    }

    b.installArtifact(exe);

    const exeRaw = b.addObjCopy(exe.getEmittedBin(), .{
        .basename = "orion.bin",
        .format = .bin,
        .pad_to = device.binaryPadding,
    });

    b.getInstallStep().dependOn(&b.addInstallBinFile(exeRaw.getOutput(), "orion.bin").step);
}
