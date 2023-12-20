const fio = @import("fio");

export fn _start(_: usize) noreturn {
    var uart = fio.uart.init(.ns16550a, .{
        .baseAddress = 0x1000_0000,
        .wordLength = .@"8",
        .stopBits = .@"1",
        .parityBit = false,
        .paritySelect = .even,
        .stickyParity = false,
        .breakSet = false,
        .dmaMode = 0,
        .divisor = 100,
    }) catch unreachable;

    while (true) {
        _ = uart.write("Hellord\n\r") catch 0;
    }
}
