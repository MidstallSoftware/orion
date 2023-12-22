const std = @import("std");
const builtin = @import("builtin");

pub const MemoryInfo = struct {
    start: usize,
    size: usize,
};

pub const Header = packed struct {
    magic: u32,
    totalsize: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rsvmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_struct: u32,

    pub inline fn valid(self: *Header) bool {
        return self.field(.magic) == 0xD00DFEED;
    }

    pub inline fn field(self: *Header, comptime f: std.meta.FieldEnum(Header)) @TypeOf(@field(self, @tagName(f))) {
        return if (builtin.cpu.arch.endian() != .big) @byteSwap(@field(self, @tagName(f))) else @field(self, @tagName(f));
    }

    pub fn findMemory(self: *Header) ?MemoryInfo {
        const buf = self.find("memory", "reg") catch return null;
        return .{
            .start = std.mem.readInt(u64, buf[0..8], .big),
            .size = std.mem.readInt(u64, buf[8..16], .big),
        };
    }

    pub fn findCpuId(self: *Header, id: usize) ?u32 {
        var buf = [_]u8{0} ** 32;
        _ = std.fmt.bufPrint(&buf, "cpu@{}", .{id}) catch return null;
        const len = blk: {
            var i: usize = 0;
            while (buf[i] != 0) : (i += 1) {}
            break :blk i;
        };
        return std.mem.readInt(u32, (self.find(buf[0..len], "reg") catch return null)[0..4], .big);
    }

    pub fn find(self: *Header, nodePrefix: []const u8, propName: []const u8) ![]u8 {
        if (!self.valid()) return error.InvalidMagic;

        var curr: [*]u32 = @ptrFromInt(@as(usize, @intFromPtr(self)) + self.field(.off_dt_struct));
        var currDepth: usize = 0;
        var foundAtDepth: ?usize = null;

        while (true) {
            const opcode = if (builtin.cpu.arch.endian() != .big) @byteSwap(curr[0]) else curr[0];
            curr += 1;

            switch (opcode) {
                0x1 => {
                    const name: [*:0]u8 = @ptrCast(curr);
                    const namelen = std.mem.len(name);
                    currDepth += 1;

                    if (foundAtDepth == null and namelen >= nodePrefix.len) {
                        if (std.mem.eql(u8, name[0..nodePrefix.len], nodePrefix)) {
                            foundAtDepth = currDepth;
                        }
                    }

                    curr += (namelen + 4) / 4;
                },
                0x2 => {
                    if (foundAtDepth) |fd| {
                        if (fd == currDepth) {
                            foundAtDepth = null;
                        }
                    }
                    currDepth -= 1;
                },
                0x3 => {
                    const nameoff = if (builtin.cpu.arch.endian() != .big) @byteSwap(curr[1]) else curr[1];
                    var len = if (builtin.cpu.arch.endian() != .big) @byteSwap(curr[0]) else curr[0];

                    const name: [*:0]u8 = @ptrFromInt(@as(usize, @intFromPtr(self)) + self.field(.off_dt_strings) + nameoff);

                    if (foundAtDepth) |fd| {
                        if (fd == currDepth) {
                            if (std.mem.eql(u8, name[0..propName.len], propName) and name[propName.len] == 0) {
                                return @as([*]u8, @ptrCast(curr + 2))[0..len];
                            }
                        }
                    }

                    len += 3;
                    curr += len / 4 + 2;
                },
                0x4 => {},
                0x9 => break,
                else => return error.UnknownOpcode,
            }
        }
        return error.NotFound;
    }
};
