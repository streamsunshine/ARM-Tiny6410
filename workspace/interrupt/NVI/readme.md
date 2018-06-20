S3C6410 - VIC - IRQ interrupt
======

## 对于非向量中断方式与向量中断方式的区别:   

1. 非向量中断    
	
	* 初始化异常向量表(固定地址0x0~0x3FF处)
	* 示例代码: [https://github.com/SeanXP/ARM-Tiny6410/tree/master/interrupt/cpsr]

2. 向量中断(Vectored Interrupt)    

	* 在特定寄存器(VICxVECTADDR)写入中断函数地址
	* 示例代码: [https://github.com/SeanXP/ARM-Tiny6410/tree/master/interrupt/irq]


------

通过在irq.c文件开头对IRQ_HANDLE_ASM宏定义进行注释或取消注释操作，选择不同的中断服务函数;

对比汇编中断函数与C语言中断函数的异同；

## ISSUE

1、按下按键后程序灯不闪烁，同时按键无效  
&esmp;问题出在mmu上面，因为interrupt的寄存器地址范围有从0x71200000开始的部分，这部分没有包含在mmu的地址映射表中。同样的问题也在start.s文件中设置中断模式栈时出现，应该注意。
