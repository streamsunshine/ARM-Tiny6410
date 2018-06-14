SECTIONS
{
    /*运行地址在SDRAM中*/
    . = 0x50000000;

    .text : {
        start.o
        clock.o
        sdram.o
        mmu.o
        led.o
        * (.text)
    }
    . = ALIGN(4);
    codeEnd = .;

    .rodata : {
        * (.rodata)
    }

    .data : {
        * (.data)
    }

    bssStart = .;
    .bss : {
        * (.bss)
    }
    bssEnd = .;
}

