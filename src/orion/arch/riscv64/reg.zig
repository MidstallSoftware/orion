pub const Register = enum {
    sstatus,
    sie,
    cycle,
    satp,
    mip,
    mie,

    pub inline fn clr(comptime self: Register, value: usize) void {
        asm volatile ("csrc " ++ @tagName(self) ++ ", %[arg1]"
            :
            : [arg1] "r" (value),
        );
    }

    pub inline fn set(comptime self: Register, value: usize) void {
        asm volatile ("csrs " ++ @tagName(self) ++ ", %[arg1]"
            :
            : [arg1] "r" (value),
        );
    }

    pub inline fn r(comptime self: Register) usize {
        return asm volatile ("csrr %[ret], " ++ @tagName(self)
            : [ret] "=r" (-> usize),
        );
    }

    pub inline fn w(comptime self: Register, value: usize) void {
        asm volatile ("csrw " ++ @tagName(self) ++ ", %[arg]"
            :
            : [arg] "r" (value),
        );
    }
};
