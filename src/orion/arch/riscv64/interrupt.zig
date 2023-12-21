const std = @import("std");
const log = std.log.scoped(.interrupt);

const Context = @import("context.zig");
const clock = @import("clock.zig");
const Register = @import("reg.zig").Register;

const IRQ_BREAKPOINT: u64 = 3;
const IRQ_S_TIMER: u64 = (0b1 << 63) + 5;

extern fn register_interrupt_handler() void;

export fn interrupt_handler(ctx: *Context, scause: usize, _: usize) void {
    disable();

    switch (scause) {
        IRQ_BREAKPOINT => {
            log.debug("Break point", .{});
            ctx.sepc += 2;
        },
        IRQ_S_TIMER => clock.handle(),
        else => {
            log.err("Interrupt scause: {x}, [sepc] = 0x{x:0>16}", .{
                scause,
                ctx.sepc,
            });
        },
    }

    enable();
}

pub fn enable() void {
    Register.sstatus.set(1 << 1);
}

pub fn disable() void {
    Register.sstatus.clr(1 << 1);
}

pub fn init() void {
    disable();
    register_interrupt_handler();
}
