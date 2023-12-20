const std = @import("std");

pub const cpu = std.Target.Cpu{
    .arch = .riscv64,
    .model = &std.Target.riscv.cpu.generic_rv64,
    .features = std.Target.riscv.cpu.generic_rv64.features,
};

pub const codeModel = std.builtin.CodeModel.medium;
pub const linker = "link.ld";
pub const assemblyFiles: []const []const u8 = &.{"asm/boot.s"};
pub const binaryPadding = 32 * 1024 * 1024;

pub const start = @import("qemu-riscv64-virt/start.zig");
