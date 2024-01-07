const std = @import("std");

pub const sdk = @import("src/orion/sdk.zig");

pub fn build(b: *std.Build) void {
    const device = sdk.standardDeviceOption(b);
    const optimize = b.standardOptimizeOption(.{});

    const target = b.resolveTargetQuery(device.crossTarget());
    const arch = device.arch();

    const fio = b.dependency("fio", .{
        .target = target,
        .optimize = optimize,
    });

    const dtree = b.dependency("dtree", .{
        .target = target,
        .optimize = optimize,
    });

    const phantom = b.dependency("phantom", .{
        .target = target,
        .optimize = optimize,
    });

    const vizops = b.dependency("vizops", .{
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
        .code_model = device.codeModel orelse arch.codeModel orelse .default,
    });

    exe.root_module.addImport("options", options.createModule());
    exe.root_module.addImport("fio", fio.module("fio"));
    exe.root_module.addImport("dtree", dtree.module("dtree"));
    exe.root_module.addImport("phantom", phantom.module("phantom"));
    exe.root_module.addImport("vizops", vizops.module("vizops"));

    if (device.linker) |linkerPath| {
        exe.linker_script = .{ .path = linkerPath };
    }

    if (device.codeModel orelse arch.codeModel) |codeModel| {
        sdk.applyCodeModel(&exe.root_module, codeModel);
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
