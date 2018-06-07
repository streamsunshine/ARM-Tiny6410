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

main:
 	// ----3. 配置GPIO-GPK相关寄存器----
	// GPKCON0-0x7F008800,Port K Configuration Register 0
	ldr r1, =0x7F008800 					
	ldr r0, =0x11110000	//0001 0001 0001 0001 0000 0000 0000 0000b;															  
						//GPK4, 位[19:16], 值为0001, 配置为Output;
						//GPK5, bit[23:20], 0001; 同理, GPK6,GPK7均为Output;
	str r0, [r1]							

led_blink:
	// 设置GPKDAT，使GPK_4/5/6/7引脚输出低电平，LED亮
	// GPKDAT - 0x7F008808, Port K Data Register
	ldr r1, =0x7F008808 					
	mov r0, #0
	str r0, [r1]		// GPKDAT全部设为0; 

	// 延时
	bl delay							

	// 设置GPKDAT，使GPK_4/5/6/7引脚输出高电平，LED灭
	ldr r1, =0x7F008808 					
	mov r0, #0xf0		// 1111 0000 b; 配置GPKDAT寄存器的bit[7:4]为高电平;
	str r0, [r1]

	// 延时
	bl delay	
	
	b led_blink

    mov pc,lr

delay:
    ldr r0,=0x100000
delayloop:
    cmp r0,#0
    sub r0,r0,#1
    bne delayloop

    mov pc,lr   //bl指令在调用时，将函数返回地址存储在lr寄存器中

  
