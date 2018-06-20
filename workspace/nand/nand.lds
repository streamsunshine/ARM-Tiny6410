SECTIONS
{
    /*运行地址在SDRAM中*/
    . = 0x50000000;

    .text : {
        start.o
        led.o
        clock.o
        sdram.o
        mmu.o
        nand.o
        uart.o
        * (.text)
    }
    . = ALIGN(4);

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

