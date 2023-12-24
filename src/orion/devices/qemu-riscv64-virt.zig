const std = @import("std");

pub const cpu = std.Target.Cpu{
    .arch = .riscv64,
    .model = &std.Target.riscv.cpu.generic_rv64,
    .features = std.Target.riscv.cpu.generic_rv64.features,
};

pub const linker = "link.ld";
pub const assemblyFiles: []const []const u8 = &.{"asm/boot.s"};

pub const includeFeatures = blk: {
    var set = std.Target.Cpu.Feature.Set.empty;
    set.addFeature(@intFromEnum(std.Target.riscv.Feature.m));
    break :blk set;
};

pub const timer = @import("qemu-riscv64-virt/timer.zig");
pub const start = @import("qemu-riscv64-virt/start.zig");
