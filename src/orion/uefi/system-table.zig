const std = @import("std");
const utils = @import("utils.zig");
const runtimeServices = @import("runtime-services.zig");

pub const configTable = [_]std.os.uefi.tables.ConfigurationTable{};

pub var tbl = utils.createTable(std.os.uefi.tables.SystemTable{
    .hdr = undefined,
    .firmware_vendor = @constCast(std.unicode.utf8ToUtf16LeStringLiteral("Midstall Software").ptr),
    .firmware_revision = 0,
    .console_in_handle = null,
    .con_in = null,
    .console_out_handle = null,
    .con_out = null,
    .standard_error_handle = null,
    .std_err = null,
    .runtime_services = &runtimeServices.tbl,
    .boot_services = null,
    .number_of_table_entries = configTable.len,
    .configuration_table = @constCast((&configTable).ptr),
});
