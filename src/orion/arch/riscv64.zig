const std = @import("std");

pub const clock = @import("riscv64/clock.zig");
pub const cpu = @import("riscv64/cpu.zig");
pub const interrupt = @import("riscv64/interrupt.zig");
pub const sbi = @import("riscv64/sbi.zig");
pub const timer = @import("riscv64/timer.zig");

pub const Context = @import("riscv64/context.zig");

pub const assemblyFiles: []const []const u8 = &.{
    "asm/interrupt.s",
};

pub const codeModel = std.builtin.CodeModel.medium;
