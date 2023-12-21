const std = @import("std");

pub const sdk = @import("src/orion/sdk.zig");

pub fn build(b: *std.Build) void {
    const device = sdk.standardDeviceOption(b);
    const optimize = b.standardOptimizeOption(.{});

    const target = device.crossTarget();
    const arch = device.arch();

    const fio = b.dependency("fio", .{
        .target = target,
        .optimize = optimize,
    });

    const options = b.addOptions();
    options.addOption([]const u8, "device", device.name);

    const exe = b.addExecutable(.{
        .name = "orion",
        .root_source_file = .{ .path = b.pathFromRoot("src/orion.zig") },
        .target = target,
        .optimize = optimize,
        .linkage = .static,
    });

    exe.addModule("options", options.createModule());
    exe.addModule("fio", fio.module("fio"));

    if (device.linker) |linkerPath| {
        exe.linker_script = .{ .path = linkerPath };
    }

    if (device.codeModel orelse arch.codeModel) |codeModel| {
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

    if (arch.assemblyFiles) |assemblyFiles| {
        for (assemblyFiles) |file| {
            exe.addAssemblyFile(.{
                .path = b.pathFromRoot(b.pathJoin(&.{
                    "src/orion/arch",
                    arch.name,
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
