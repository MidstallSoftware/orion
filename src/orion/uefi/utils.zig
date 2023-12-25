const std = @import("std");

pub const rev: u32 = (2 << 16) | 100;

pub fn createTable(in: anytype) @TypeOf(in) {
    const T = @TypeOf(in);
    var value = in;
    value.hdr = .{
        .signature = T.signature,
        .revision = rev,
        .header_size = @sizeOf(T),
        .crc32 = 0,
        .reserved = 0,
    };
    return value;
}
