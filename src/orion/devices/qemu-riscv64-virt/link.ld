ENTRY(_boot);
SECTIONS {
    . = 0x80000000;
    firmware_start = 0x80000000;

    .bootblock :
    {
        KEEP(*(.bootblock.boot));
    }

    .text : {
        KEEP(*(.text.entry))
        *(.text .text.*)
    }

    .rodata : ALIGN(4) {
        srodata = .;
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
        erodata = .;
    }

    .data : ALIGN(4) {
        sdata = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        edata = .;
    }

    sidata = LOADADDR(.data);

    .bss (NOLOAD) : ALIGN(4) {
        *(.bss.uninit)
        sbss = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        ebss = .;
    }

    .stack_sizes (INFO) : {
        KEEP(*(.stack_sizes));
    }

    /DISCARD/ : {
        *(.eh_frame)
    }

    firmware_end = .;
}
