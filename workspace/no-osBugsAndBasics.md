# Bugs And Basics
 记录编译裸机时候的一些错误和有关编译的一些基础知识。

## 目录

 [1、C启动文件和标准库文件](#1Bugs)  
 [2、文件链接顺序问题](#2Basics)  
 [3、volatile的使用](#3Basics)  
 [4、#pragram的作用](#4Basics)  
 [5、交叉编译链的构建](#5Basics)  
 [6、时钟配置和调用时机](#6Basics)  
 [7、启动流程](#7Basics)  
        
### 1Bugs
 连接程序时报"undefined reference to '__aeabi_unwind_cpp_pr0'"
 C语言程序在连接时，会自动连接启动文件和库文件。启动文件用来做C程序的入口。当连接器找不到相应的文件时，就会报错，可以给连接器添加-nostdlib选项解决错误，但是要自己编写start.s作为启动程序（其中包含堆栈的设置，跳转到main函数以及跳出main函数后程序循环等待）。-nostdlib选项作用是不连接系统标准启动文件和标准库文件，只将指定的文件传递给链接器。

 在编译基于系统的程序时，一般是需要链接启动文件和库文件的，编译裸机程序并不需要。

### 2Basics
 在链接裸机程序的时候，需要将启动文件和C文件链接在一起，由于一般ARM会从某一个地址开始执行程序，所以编译程序的时候需要将start.s程序指定到这个地址段（通过-Ttext实现），但是在链接的时候是怎么实现的呢？

 已知的一种方法是通过lds文件指定程序的入口，这样编译程序的时候，就会将对应入口函数放到编译成的二进制文件的首部。那么在不使用lds文件的时候，链接器是如何安排程序的链接顺序的呢？

链接器会按照.o文件的顺序依次将其代码段，数据段等提取出来，依次放置在生成的二进制文件中。所以在链接裸机程序，且没有使用lds时需要将start.s生成的start.o放置在C程序前面。

将start.s放在c程序前面的另一个原因是，符号的解析顺序。链接时，链接器会将没有定义的符号存储在A存储器中，如果在后面找到了符号定义，就将其从A中除去，如果最后A中仍有未解析的符号，则报错。因此，需要将被依赖的放在依赖的后面，由于start.s依赖c程序中的main函数，所以需要将start.s放在前面。

### 3Basics
 voiatile变量提醒编译器，变量随时可能发生变化，，因此，每次用到该变量的时候都需要从内存读取。编译器不要对其进行优化。可以用于以下几个方面。

 1、防止函数被优化。比如在使用单纯的减计数程序进行延时，编译器的优化选项可能将其优化掉（因为这个程序看起来没有），加入volatile可以避免这种情况发生，

 2、定义寄存器。由于寄存器的值可能随时改变，需要将其定义成volatile类型。由于寄存器是在固定地址的，所以就需要定义一个在固定地址处的volatile变量，有以下几种方案：
```
//宏定义
#define GPIO_CON (*(unsigned int *)0x70000080)

//定义代码段，利用lds文件将其定位到固定地址
//以DSP28335为例
union SCICCR_REG {
    Uint16              all;
     struct SCICCR_BITS  bit;
};

struct SCI_REGS{
    union SCICCR_REG     SCICCR;
    union SCICTL1_REG    SCICTL1;
    /*SCI模块的其他寄存器
      ....
    */
};
#pragma DATA_SECTION(SciaRegs,"SciaRegsFile");
volatile struct SCI_REGS SciaRegs;

//在最终定义结构体是加上volatile并通过#pragram将结构体指定到SCI模块的寄存器空间首地址处。

//定义指向结构体的指针，结构体中的成员定义为volatile类型。
//以ARM cortex4的28335为例
#define     __IO    volatile 
typedef struct{
    __IO uint32_t SC1[ADC_SC1_COUNT];
    __IO uint32_t CFG1; 
    /*ADC模块的其他寄存器
      ...
    */
}ADC_Type, *ADC_MemMapPtr;
#define ADC0_BASE                                (0x4003B000u)
#define ADC0                                     ((ADC_Type *)ADC0_BASE)

```

### 4Basics
\#pragma作用
* 设置编译器状态，指示编译器完成特定的指令。
* 这种指示或者指令对于不同的编译器是不同的。

这里介绍的是softune对应编译器的#pragma

#### Softune的#pragma section
通用格式

\#pragma section DEFSECT[=NEWNAME][,attr=SECTATTR][,locate=ADDR] 

注意：
1.#pragma section影响整个源文件，如果指定多个最后一个有效
```
[Example] 
Input:   #pragma section CODE=program,attr=CODE,locate=0xff
         void main(void){}
Output:
                 .SECTION   program, CODE, LOCATE=0x000000FF,
         ;-------begin_of_function
                 .GLOBAL _main
         _main:
                 ST     RP, @-SP
                 ENTER  #4
         L_main:
                 LEAVE
                 LD     @SP+, RP
                 RET

```

#### Softune的#pragma segment
通用格式

\#pragma segment DEFSECT[=NEWNAME][,attr=SECTATTR][,locate=ADDR] 

注意：

1.等号前后不能有空格  
2.#pragma segment在函数定义、变量定义和变量声明的时候起作用。  
3.作用从描述行开始直到下一个#pragma segment结束。  
（与#pragma section有区别）
4.Intvect段不能被指定  
5.如果一个变量在两个#pragma segment中，前面的那个有效

### 5Basics

 交叉编译链只需下载对应ARM的就可以使用，因为重要的是ARM体系的指令集。

 安装交叉工具链：
* 到网站上下载一个交叉工具链的包。
* 解压缩的一个文件夹
* 在解压缩后的文件夹中找到bin目录，它下面应该有arm***gcc/ld/objcopy等，将bin目录的绝对路径添加到/etc/environment文件中（也可以不添加，但需要在makefile中指明）

通过上述操作交叉编译链即可正常使用。

### 6Basics

&emsp;时钟是芯片运行的基础,可使用汇编语言和C语言进行配置。主要关注时钟源（晶振或外部信号），PLL的配置，时钟源的选择，分配。配置时钟一般可以借助时钟树来辅助。另外，计算方法也需要关注。  
&emsp;由于时钟比较重要，一般在系统启动文件中就进行设置，直接使用跳转指令进行设置即可。

### 7Basics

&emsp;6410 Booting模式配置，是通过OM[4:0]、XSELNAND、GPN[15:13]共同决定:   

#### OM[4:0]

&emsp;也可能称为XOM。OM[4:0]是6410的5个外部引脚。
* OM[4:1]决定了S3C6410的启动模式。可以有SROM,NOR,OneNAND,MODEM和Internal ROM（IROM）
* 启动OM[0]决定了S3C6410的外部时钟源:  
	* OM[0] = 0, XEXTCLK, 外部时钟(external clock);
	* OM[1] = 1, XXTIpll, 外部晶振(external crystal;

[说明OM是外部引脚的参考链接](http://blog.chinaunix.net/uid-28720832-id-3529874.html)

#### XSELNAND

&emsp;用来配置NANDFlash。  
* When NAND Flash device is used, XSELNAND pin must be 1, even if it is used as boot device or storage device.   
* When OneNAND Flash device is used, XSELNAND must be 0, even if it is used as boot device or storage device.   
* When NAND/OneNAND device is not used, XSELNAND can be 0 or 1.
 OM[4:1] 决定NOR，NAND，SROM，MODEM还是IROM。
* 
* 选择NAND Flash Booting模式时，XSELNAND = 1; 
* 选择ONENAND时，XSELNAND = 0;
* 其它几种Booting模式，XSELNAND可以0或1。
===

&emsp;6410支持SROM、ONENAND、IROM等几种Booting模式，其中最常用的是IROM下的NAND Flash和SD/MMC两种启动模式;   
&emsp;参考: S3C6410X.PDF - Page 123 - 3.3.3 CLOCK SOURCE SELECTION

#### SROM Booting

&emsp;寄存器配置： XSELNAND = X, OM[4:1]=0100 / 0101;    
8bit或16bit SROM启动模式;  
这儿SROM一般情况下指的是Nor Flash，系统上电之后，
Boot镜像区为SROM控制器的第0个bank（128MB），即0x10000000~0x17FFFFFF地址的映射，
内核PC从0x0开始取指令实际是从SROM的bank0开始取指令运行。

#### ONENAND Booting

&emsp;寄存器配置： XSELNAND = 0, OM[4:1]=0110; 
ONENAND Flash启动模式，此时整个Boot镜像区0x0~0x07FFFFFF全部为静态存储器0x20000000~0x27FFFFFF地址镜像，
128MB一一对应，静态存储器0x20000000~0x27FFFFFF地址刚好是ONENAND Flash Bank0地址域，
内核PC从0x0开始取指令实际是从ONENAND Flash Bank0开始取指令运行。

#### MODEM Booting  

&emsp;寄存器配置： XSELNAND = X, OM[4:1]=0111;    

MODEM 启动模式，S3C6410的MODEM启动，指的外部HOST MODEM通过6410间接MODEM接口（indirect MODEM interface），
将启动代码传输到6410的内部 8KB stepping stone区域，然后通过设置协议寄存器（protocol register）系统控制寄存器（位于bank 0x0B）的bit0，激活s3c6410 MEODOM booting功能。

MODEM Booting基本流程：  
在6410上电之后，ARM内核PC从地址0x0开始取指令，此时Boot镜像区0x0开始的32KB为6410内部I_ROM地址 0x08000000~0x08007FFF的32KB数据的镜像，
所以当PC从0x0开始取指令执行，实际是从I_ROM 0x08000000处开始执行代码，
而I_ROM区32KB存放的是6410出厂固化的一段启动代码，
这段代码会自动根据是MODEM Boot启动配置，初始化MEDEM 主机接口，
从HOST处接收固件到8KB stepping stone区域，直至HOST激活MEODOM booting功能，
ARM内核PC跳转到stepping stone开始处执行代码。

有些资料在说明6410MODEM boot功能时候，有一种说法是6410通过直接MODEM接口（Direct MODEM interface）下载启动代码到“Direct MODEM interface”内部8KB双向RAM
然后启动s3c6410 MEODOM booting功能，这种说明不正确，
仔细阅读6410 使用说明，很容易知道6410 的MEDOM booting 功能是通过其indirect MODEM interface 直接下载启动代码到6410内部的8k stepping stone区域，
而后跳转到stepping stone继续运行（关于8K stepping stone在IROM Booting有详细说明）。

#### IROM Booting

&emsp;寄存器配置： OM[4:1]=1111;  

当OM[4:1]=1111，对应系统选择当IROM启动模式，
根据GPN[15:13]不同选择，IROM Boot又细分成SD/MMC、ONENAND、NAND Flash三种启动方式。
IROM Booting配置启动主要的特点是：首先上电之后Boot镜像区地址为0x00000000~0x00007FFF 的
32KB区域为6410内部的I_ROM区低32KB字节0x08000000~0x08007FFF区域数据的镜像，
ARM 内核从0x0取指令实际是从已经存储6410出厂固化代码的I_ROM区低32KB。
其次是I_ROM 32KB会根据GPN[15:13]的不同设定，执行不同的代码搬移工作，
比如当为NAND Flash启动设定，I_ROM 32KB会初始化NAND Flash控制器，搬移NAND Flash 的低8KB数据到6410内部的8k stepping stone区域，
然后跳转到8k stepping stone处运行代码。

ONENAND Flash(XSELNAND = 0，OM[4:1]=0110) Booting与IROM里面的ONENAND Flash Booting(XSELNAND =0，OM[4:1]=1111,GPN[15:13]=001)，
两种模式有本质上不同，前者是直接从ONENAND Flash直接运行启动代码，而后者是先是BL0搬移ONENAND Flash 前8K代码到Stepping stone，
而后跳转到Stepping stone运行。

#### IROM Booting详细解释 

IROM Booting流程分2个阶段BL0和BL1:   

1. BL0为系统上电之后，最先执行I_ROM 32KB代码，搬移8KB（从NAND Flash、SD/MMC、ONENAND Flash等几者之一）代码到stepping stone，
然后跳转到stepping stone处执行，这段代码是6410出厂已经固化的代码，无需我们干预；
2. BL1为内核在stepping stone执行的流程，功能需要我们自己实现，
BL1主要是将除（NAND Flash、SD/MMC、ONENAND Flash等几者之一）8K之外的其他启动代码拷贝到SDRAM里面，
然后跳转到SDRAM执行，至此完成BL1。

##### BL0 流程详细说明

参考: 《s3c6410 IROM Booting ApplicationNote V1.0》    
参考: http://blog.csdn.net/loongembedded/article/details/6637461    

系统上电或复位之后，BL0主要执行以下操作：   
* 禁止看门狗时钟；
* 初始化TCM(主要初始化TCM0 的 Secure Key和4KB堆，TCM1的8KB 堆栈)
* 初始化块设备拷贝函数
* 初始化堆栈
* 初始化PLL
* 初始化I-Cache
* 初始化堆
* Copy BL1到stepping stone
* 确认BL1的完整性
* 跳转到BL1

#### s3c6410的启动流程解析

&emsp;1、s3c6410IROM启动过程分成BL0, BL1, BL2几个阶段。其中BL0是固化在s3c6410内部的IROM中的, 该段程序根据所选择的启动模式从存储介质加载BL1。  
&emsp;2、s3c6410支持从多种存储介质中启动，nandflash, sd卡，sdhc卡，OneNand, MoviNand.... 其中，BL1和BL2存储于这些存储介质中，BL1的8K数据由BL0的程序自动加载到s3c6410的stepping stone中运行。  
&emsp;BL1,BL2的存储位置固定。对于sd卡, BL1位于 (totalSector - 18) 的扇区；对于sdhc卡，BL1位于(totalSector-1042)的扇区。BL1由BL0加载到 0x0C000000处运行，大小为8K.  

S3C6410中的IROM(位于0x0800_0000-0x08FF_FFFF中间的一段（这里实际物理地址空间为32KB），被映射到0x0000_0000-0x07FF_FFFF这段称为引导镜像区的区域),CPU上电后先执行IROM的程序（初始化、从启动设备中读取前8K数据到Stepping Stone、跳转到Stepping Stone执行程序）

Stepping Stone(Boot Loader)      
&emsp;0x0C00_0000 ~ 0x0FFF_FFFF (64MB)这里实际物理地址空间只有8K SDRAM。大于8KB的程序要到DRAM中执行，对于这种情况，NANDFLASH拷贝到这里的8KB程序中应该包括，NAND FLASH初始化程序，DRAM初始化程序，拷贝程序。 最后跳转到DRAM中。

DRAM  
    0x5000_0000 ~ 0x5FFF_FFFF (256MB)    
	0x6000_0000 ~ 0x6FFF_FFFF (256MB)    
&emsp;Friendly ARM - Tiny6410使用DRAM Controller驱动Mobile SDRAM芯片。因此其内存对应的其实地址为0x5000_0000;
	* 程序的Makefile文件中，指定链接地址:
		
			arm-linux-ld -Ttext 0x50000000 -o led.elf $^
	* 在链接脚本中，配置地址为0x5000_0000;
	


