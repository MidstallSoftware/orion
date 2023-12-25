const std = @import("std");
const Allocator = std.mem.Allocator;

pub const runtimeServices = @import("uefi/runtime-services.zig");
pub const systemTable = @import("uefi/system-table.zig");

pub fn init(_: Allocator) !void {
    std.os.uefi.system_table = &systemTable.tbl;
}

comptime {
    _ = runtimeServices;
    _ = systemTable;
}
