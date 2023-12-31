const std = @import("std");
const log = std.log.scoped(.interrupt);

const Context = @import("context.zig");
const cpu = @import("cpu.zig");

fn interruptHandler(ctx: *Context, cause: usize) void {
    switch (cause) {
        3 => {
            cpu.list[cpu.hartId()].processIpi();
        },
        7 => {
            cpu.Register.mie.clr(1 << 7);
            cpu.Register.mip.set(1 << 5);
        },
        else => {
            std.debug.panic("Interrupt cause: {x}, [mepc] = 0x{x:0>16}", .{
                cause,
                ctx.mepc,
            });
        },
    }
}

export fn trap_handler(ctx: *Context, mcause: usize, _: usize) void {
    if (mcause & ~@as(usize, 0x8000000000000000) != 0) {
        interruptHandler(ctx, mcause);
        return;
    }

    std.debug.panic("Could not handle trap {}", .{mcause});
}
