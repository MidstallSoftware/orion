const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");

pub const std_options = struct {
    pub const log_level = .info;
    pub const logFn = log;
};

pub const arch = blk: {
    const arches = @import("orion/arch.zig");

    for (std.meta.declarations(arches)) |decl| {
        if (std.mem.eql(u8, decl.name, @tagName(builtin.cpu.arch))) {
            break :blk @field(arches, decl.name);
        }
    }
    unreachable;
};

pub const device = blk: {
    const devices = @import("orion/devices.zig");

    for (std.meta.declarations(devices)) |decl| {
        if (std.mem.eql(u8, decl.name, options.device)) {
            break :blk @field(devices, decl.name);
        }
    }
    unreachable;
};

pub usingnamespace if (@hasDecl(device, "panic")) struct {
    pub const panic = device.panic;
} else if (@hasDecl(arch, "panic")) struct {
    pub const panic = arch.panic;
} else struct {};

pub const dtb = @import("orion/dtb.zig");

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (@hasDecl(device, "start")) {
        if (@hasDecl(device.start, "uart")) {
            nosuspend device.start.uart.writer().print("[" ++ @tagName(scope) ++ "] (" ++ @tagName(message_level) ++ "): " ++ format ++ "\n\r", args) catch return;
        }
    }
}

comptime {
    _ = arch;
    _ = device;

    if (@hasDecl(device, "start")) {
        _ = device.start;
    }
}
