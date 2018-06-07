//Boot code

.global _start

_start:
/*ARM1176jzf-s将存储地址和外设接口分开了，初始化时要告知CP15哪一段是
 外设地址以及外设地址大小，否则将对应地址按照存储器访问，将不能访问到实际外设
 参见ARM1176jzfs芯片手册3.2.49*/
/*根据地址映射可知，存储器地址范围0-0x6000 0000
  外设地址范围 0x7000 0000 - 0x7fff ffff */
    ldr r0,=0x70000000
    orr r0,r0,#0x13     //code meaned 256M
    mcr p15,0,r0,c15,c2,4

//关闭看门狗
    ldr r0,=0x7E004000
    mov r1,#0
    str r1,[r0]

//设置栈，就是设置SO寄存器，让其指向一块可用的内训。SD启动时，S3c6410内部的8K的SRAM被映射到0xc000000而默认栈是递减的，所以可以让SP指向0xc002000
    ldr sp,=0xC002000

    bl main

halt:
    b halt

 
