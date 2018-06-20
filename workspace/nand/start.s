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

// 开启icache 提高取指令速度
//CP15 协处理器的寄存器1 的bit[12]写1启动icache，写0关闭icache
    mov r0,#0
    orr r0,r0,#0x00001000
    mcr p15,0,r0,c1,c0,0

//设置时钟
    bl ClockInit
//SDRAM使用前，需要设置DRAM控制器，进行初始化,初始化过程也类似于寄存器配置
    bl sdram_init
//初始化nand
    bl nand_init
//将程序从stepstone 拷贝到 sdram中
    adr r0,_start
    ldr r1,=_start

//比较当前地址和运行地址是否相同，若相同直接进入清空Bss阶段
    cmp r0,r1
    beq CleanBss

//直接从Nand Flash复制代码,r0,r1,r2分别对应第一，二，三个参数
    ldr r2,=bssStart
    sub r2,r2,r1
    //
    bl copy2addr
//复制代码到目的地址中

CleanBss:
    ldr r0,=bssStart
    ldr r1,=bssEnd
    cmp r0,r1
    beq JumpToMMU 

    mov r2,#0
CleanLoop:
    str r2,[r0],#4
    cmp r0,r1
    bne CleanLoop

//跳转到主函数
JumpToMMU:
 //初始化MMU
    bl mmu_init

    ldr pc,=main

halt:
    b halt


