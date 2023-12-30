const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");

pub const std_options = struct {
    pub const log_level = if (builtin.mode == .Debug) .debug else .info;
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

pub const drivers = @import("orion/drivers.zig");
pub const main = @import("orion/main.zig");
pub const uefi = @import("orion/uefi.zig");

pub fn panic(msg: []const u8, stackTraceOpt: ?*std.builtin.StackTrace, retAddr: ?usize) noreturn {
    const logger = std.log.scoped(.panic);

    logger.err("0x{x}: {s}", .{ retAddr orelse @returnAddress(), msg });

    if (stackTraceOpt) |stackTrace| {
        logger.err("Stack trace:", .{});
        for (stackTrace.instruction_addresses) |addr| {
            logger.err("\t0x{x}", .{addr});
            if (addr == 0) break;
        }
    }
    while (true) @breakpoint();
}

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

    if (@hasDecl(arch, "interrupt")) {
        _ = arch.interrupt;
    }

    if (@hasDecl(device, "start")) {
        _ = device.start;
    }
}
