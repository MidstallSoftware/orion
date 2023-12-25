const std = @import("std");
const utils = @import("utils.zig");

pub const tbl = utils.createTable(std.os.uefi.tables.RuntimeServices{
    .hdr = undefined,
    .getTime = getTime,
    .setTime = setTime,
    .getWakeupTime = getWakeupTime,
    .setWakeupTime = setWakeupTime,
    .setVirtualAddressMap = setVirtualAddressMap,
    .convertPointer = convertPointer,
    .getVariable = getVariable,
    .getNextVariableName = getNextVariableName,
    .setVariable = setVariable,
    .getNextHighMonotonicCount = getNextHighMonotonicCount,
    .resetSystem = resetSystem,
    .updateCapsule = updateCapsule,
    .queryCapsuleCapabilities = queryCapsuleCapabilities,
    .queryVariableInfo = queryVariableInfo,
});

fn getTime(timeOut: *std.os.uefi.Time, cap: ?*std.os.uefi.TimeCapabilities) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = timeOut;
    _ = cap;
    return .Unsupported;
}

fn setTime(time: *std.os.uefi.Time) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = time;
    return .Unsupported;
}

fn getWakeupTime(enabled: *bool, pending: *bool, time: *std.os.uefi.Time) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = enabled;
    _ = pending;
    _ = time;
    return .Unsupported;
}

fn setWakeupTime(enabled: *bool, time: ?*std.os.uefi.Time) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = enabled;
    _ = time;
    return .Unsupported;
}

fn setVirtualAddressMap(mmapSize: usize, descSize: usize, ver: u32, mmap: [*]std.os.uefi.tables.MemoryDescriptor) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = mmapSize;
    _ = descSize;
    _ = ver;
    _ = mmap;
    return .Unsupported;
}

fn convertPointer(debugDispos: usize, addr: **anyopaque) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = debugDispos;
    _ = addr;
    return .Unsupported;
}

fn getVariable(name: [*:0]const u16, vendorGuid: *align(8) const std.os.uefi.Guid, attribs: ?*u32, size: *usize, data: ?*anyopaque) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = name;
    _ = vendorGuid;
    _ = attribs;
    _ = size;
    _ = data;
    return .Unsupported;
}

fn getNextVariableName(nameSize: *usize, name: [*:0]u16, vendorGuid: *align(8) std.os.uefi.Guid) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = nameSize;
    _ = name;
    _ = vendorGuid;
    return .Unsupported;
}

fn setVariable(name: [*:0]const u16, vendorGuid: *align(8) const std.os.uefi.Guid, attribs: u32, size: usize, data: *anyopaque) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = name;
    _ = vendorGuid;
    _ = attribs;
    _ = size;
    _ = data;
    return .Unsupported;
}

fn getNextHighMonotonicCount(value: *u32) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = value;
    return .Unsupported;
}

fn resetSystem(resetType: std.os.uefi.tables.ResetType, status: std.os.uefi.Status, dataSize: usize, data: ?*const anyopaque) callconv(std.os.uefi.cc) noreturn {
    _ = resetType;
    _ = status;
    _ = dataSize;
    _ = data;
    @panic("Not supported");
}

fn updateCapsule(capsules: **std.os.uefi.tables.CapsuleHeader, count: usize, scatter: u64) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = capsules;
    _ = count;
    _ = scatter;
    return .Unsupported;
}

fn queryCapsuleCapabilities(capsules: **std.os.uefi.tables.CapsuleHeader, count: usize, maxSize: *usize, resetType: std.os.uefi.tables.ResetType) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = capsules;
    _ = count;
    _ = maxSize;
    _ = resetType;
    return .Unsupported;
}

fn queryVariableInfo(attribs: *u32, maxStoreSize: *u64, remSize: *u64, maxSize: *u64) callconv(std.os.uefi.cc) std.os.uefi.Status {
    _ = attribs;
    _ = maxStoreSize;
    _ = remSize;
    _ = maxSize;
    return .Unsupported;
}
