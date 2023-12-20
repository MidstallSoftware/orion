const std = @import("std");

pub const cpu = std.Target.Cpu{
    .arch = .riscv64,
    .model = &std.Target.riscv.cpu.sifive_u74,
    .features = std.Target.riscv.cpu.sifive_u74.features,
};

pub const codeModel = std.builtin.CodeModel.medium;

pub const excludeFeatures = blk: {
    var set = std.Target.Cpu.Feature.Set.empty;
    set.addFeature(@intFromEnum(std.Target.riscv.Feature.d));
    break :blk set;
};
