const std = @import("std");

pub const Register = enum {
    sstatus,
    mstatus,
    sie,
    cycle,
    satp,
    mip,
    mie,
    mcounteren,
    misa,
    mideleg,

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

pub fn hartId() usize {
    return asm volatile ("mv %[result], tp"
        : [result] "=r" (-> usize),
    );
}

pub fn getTime() usize {
    return asm volatile ("rdtime %[result]"
        : [result] "=r" (-> usize),
    );
}

pub const mprv = struct {
    pub fn readFlagsUsize(flags: usize, p: ?*usize) usize {
        return asm volatile (
            \\csrs mstatus, %[arg1]
            \\lw %[ret], 0(%[arg2])
            \\csrc mstatus, %[arg1]
            : [ret] "=r" (-> usize),
            : [arg1] "r" (flags),
              [arg2] "r" (p),
            : "memory"
        );
    }

    pub inline fn readUsize(p: ?*usize) usize {
        return readFlagsUsize(0x20000, p);
    }
};

pub const Cpu = struct {
    ipiPending: isize = 0,

    pub fn processIpi(self: *Cpu) void {
        if ((self.ipiPending & 1) == 1) {
            Register.mip.set(1 << 1);
        } else if ((self.ipiPending & 2) == 2) {
            asm volatile ("fence.i");
        } else if ((self.ipiPending & 4) == 4) {
            asm volatile ("sfence.vma");
        } else if ((self.ipiPending & 8) == 8) {
            asm volatile ("sfence.vma");
        } else if ((self.ipiPending & 16) == 16) {
            while ((self.ipiPending & 16) == 16) {
                asm volatile ("wfi");
            }
        }
    }
};

// TODO: use the dtb to determine the size of the array
pub var list = [1]Cpu{.{}};
