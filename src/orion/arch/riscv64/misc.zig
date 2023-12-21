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
