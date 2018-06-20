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

    .rodata : {
        * (.rodata)
    }

    .data : {
        * (.data)
    }

    . = ALIGN(4);
    bssStart = .;
    .bss : {
        * (.bss)
    }
    bssEnd = .;
}

