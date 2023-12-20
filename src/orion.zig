const std = @import("std");
const options = @import("options");

pub const devices = @import("orion/devices.zig");

comptime {
    for (std.meta.declarations(devices)) |decl| {
        if (std.mem.eql(u8, decl.name, options.device)) {
            const device = @field(devices, decl.name);

            if (@hasDecl(device, "start")) {
                _ = device.start;
            }
            break;
        }
    }
}
