# NAND NOR OneNAND

[本目录代码详解](#代码详解)

## 概念

**SLC**：single level cell，一个cell存储一个bit，只有高低电平，擦写次数可达10万次。  
**MLC**：multi level cell，一个cell存储两个bit，擦写次数一万次。  
**TLC**：Triple level cell，一个cell存储三个bit，擦写次数5000次左右，很少达到一万次。  
&emsp;三者都是Nand flash一个位置的存储结构，从上到下，存储密度依次增加，操作难度一次增大。

## 比较

![Nand OneNand Nor](Nand_OneNand_Nor.png)

其中Nor支持XIP，XIP是指在flash上运行程序,需要能够随机访问。

Nor：块大小64~128KB，擦写一个块4s，擦写次数1万次，位反转少。  
Nand：块大小8~64KB，擦写一个块2ms，擦写次数可达10万次，容易位反转。

## Nand接口和访存

1、接口：8个IO引脚，5个使能信号（nWE,ALE,CLE,nCE,nRE）、1个状态引脚（RDY/B）、1个写保护引脚（nWP）。

2、过程：先传输命令，然后传输地址，最后读写数据，期间要检查flash状态。使用CLE表示命令，ALE表示地址。读操作，先发送命令字（50h/00h/01h），发送地址序列，等待R/nB引脚为高，读数据。写命令一般以页为单位，先发送80h，然后地址序列，最后发送10h启动 操作，通过70h读flash状态,确定是否成功。擦除先发送60h，然后地址，然后发送D0h启动操作，70h查询状态，确定是否成功。

3、结构：行列结构：器件>块>页。以K9F1208U0M为例，528Mbit=4096块，1块=528B\*32页（行），1页=(512+16)字节，其中每一个字节对应一个列。由于8个IO只能访问256个位置，所以需要使用不同的指令访问A区0~255（00h），B区256~511（01h），C区512~527（50h）。  
&emsp;存储层，一个器件可分为几个存储层。以K9F1208U0M为例，其有4个存储层（plane），每个存储层有1024个block和一个528字节的寄存器，这可以同时写多个页。

4、Nand控制器，为了简化操作，使用控制器。通过操作寄存器完成存储器操作。首先配置配置寄存器，然后命令寄存器，地址寄存器，状态寄存器，数据寄存器。

    
Tiny6410 - NAND Flash Controller
====

###Stepping Stone
The S3C6410X is equipped with an internal SRAM buffer called ‘Steppingstone’.    Generally, the boot code will copy NAND flash content to SDRAM. Using hardware ECC, the NAND flash data validity will be checked. After the NAND flash content is copied to SDRAM, main program will be executed on SDRAM.    To use NAND Flash, 'XSELNAND' pin must be connected to High Level. (原理图Tiny6410-1308.pdf中，'XSELNAND'引脚连接VDD3V3)


### Nand Flash Features

1. NAND Flash memory I/F: Support 512Bytes and 2KB Page .2. Software mode: User can directly access NAND flash memory. for example this feature can be used in read/erase/program NAND flash memory.3. Interface: 8-bit NAND flash memory interface bus.4. Hardware ECC generation, detection and indication (Software correction).5. Support both SLC and MLC NAND flash memory : 1-bit ECC, 4-bit and 8-bit ECC for NAND flash.(Recommend: 1bit ECC for SLC, 4bit and 8bit ECC for MLC NAND Flash)6. SFR I/F: Support Byte/half word/word access to Data and ECC Data register, and Word access to other registers7. SteppingStone I/F: Support Byte/half word/word access.8. The Steppingstone 8-KB internal SRAM buffer can be used for another purpose . (S3C6410 Stepping Stone: 0x0C000000 ~ 0x0C001FFF (8K) )

### NAND Flash Chip
SAMSUNG K9K8G08U0E-SCB0, 8G bit Nand Flash,1Gx8 SLC(1G字节)        
K9F4G08U0E , K9K8G08U0E, 同一个芯片手册;

型号说明：
<http://www.elnec.com/device/Samsung/K9F4G08U0E+%5BTSOP48%5D/>

	- K = Memory
	- 9 = NAND Flash
	- F = SLC Normal ; K = SLC Die Normal, SLC Die stack;
	- Density: 4G = 4Gbit, 8G = 8Gbit;
	- Technology: 0 = Normal (x8)
	- Organization: 8 = x8
	- Supply Voltage: U = 2.7V to 3.6V
    - Mode: 0 = Normal
	- Generation: E = 6th generation
	

![Array Organization](Array_Organization.png)

K9K8G08U0E:     

* 1 Page = (2K + 64) Bytes
* 1 Block = (2k + 64)B x 64 Pages = (128K + 4K) Bytes
* 1 Device = (2K + 64)B x 64 Pages x 8,192 Blocks = 8,448 Mbits = (8192 + 256)Mbits    
* 其中可用空间为8192Mbits(1GB), 另外256Mbits(32M)存放ECC校验码;

![Functional Block Diagram](Functional_Block_Diagram.jpg)
NAND芯片只有8条I/O线，命令、地址、数据都要通过这8个I/O口输入输出。这种形式减少了NAND芯片的引脚个数，并使得系统很容易升级到更大的容量（强大的兼容性）。

* 写入命令、地址或数据时，都要将WE#,CE#信号同时拉低
* 数据在WE#信号的上升沿被NAND Flash锁存
* 命令锁存信号CLE，地址锁存信号ALE用来分辨、锁存命令/地址。
* K9K8G08U0E的1GB存储空间，需要30位地址(2^30 = 1GB, address[29:0])，因此以字节为单位访问Nand Flash时需要5个地址序列：
	* 1st Cycle, (A0~A7)
	* 2st Cycle, (A8~A11)
	* 3st Cycle, (A12~A19)
	* 4st Cycle, (A20~A27)
	* 5st Cycle, (A28~A29)
* 列地址(A0~A10), 11根地址线, 从0x000 ~ 0x7ff(0b0111\_1111\_1111), 共2^11=2048个字节;
* 行地址(A11~A29), 19根地址线, 2^19=512K个页面;
	* 页地址(Page Address): A11 ~ A16, 2^6=64页;
	* 块地址(Block Address): A17 ~ A29, 2^13=8192块;

* **SLC**    
	传统上，每个存储单元内存储1个信息比特，称为单阶存储单元（Single-Level Cell,SLC），使用这种存储单元的闪存也称为单阶存储单元闪存（SLC flash memory），或简称SLC闪存。SLC闪存的优点是传输速度更快，功率消耗更低和存储单元的寿命更长。然而，由于每个存储单元包含的信息较少，其每百万字节需花费较高的成本来生产。
* **MLC**     
	多阶存储单元（Multi-Level Cell,MLC）可以在每个存储单元内存储2个以上的信息比特，其“多阶”指的是电荷充电有多个能阶（即多个电压值），如此便能存储多个比特的值于每个存储单元中。借由每个存储单元可存储更多的比特，MLC闪存可降低生产成本，但比起SLC闪存，其传输速度较慢，功率消耗较高和存储单元的寿命较低，因此MLC闪存技术会用在标准型的储存卡。
* **TLC**     
	三阶储存单元（Triple-Level Cell, TLC），这种架构的原理与MLC类似，但可以在每个储存单元内储存3个信息比特。TLC的写入速度比SLC和MLC慢，寿命也比SLC和MLC短，大约1000次。现在，厂商已不使用TLC这个名字，而是称其为3-bit MLC。
	
###硬件连接

| S3C6410 | I/O | K9K8G08U0E |
| :-----: | :-: | :--------: |
| Xm0DATA0 ~ Xm0DATA7| R/W | IO0 ~ IO7(I/O引脚)|
| Xm0RPn/RnB/GPP7| R | R/nB(就绪/忙碌状态信号)|
| Xm0RDY0/ALE/GPP3 | W | ALE(地址锁存信号) |
| Xm0RDY1/CLE/GPP4 | W | CLE(命令锁存信号) |
| Xm0CSn2/GPO0 | W | nCE(芯片使能, 低电平有效) |
| Xm0INTsm1/FREn/GPP6 | W | nRE(读使能, 低电平有效) |
| Xm0INTsm0/FWEn/GPP5 | W | nWE(写使能, 低电平有效) |
| VDD3V3 | W | nWP(写保护, 低电平有效) |

备注: 通常在信号前加'n'表示低电平有效:  

* R/nB, 高电平为Ready, 低电平为Busy;
* nCE, 低电平有效，使能芯片;
* nWE, nRE, 低电平有效，写/读使能;
* ALE, CLE, 高电平有效, 地址/命令锁存信号;
	
### Command Sets
| Function | 1st Cycle | 2nd Cycle | Acceptable Command during Busy | 
| :------: | :-------: | :-------: | :----------------------------: |
| Read | 00h | 30h | |
| Read for Copy Back | 00h| 35h||
|Read ID|90h|-||
|Reset|FFh|-|O|
|Page Program|80h|10h||
|Two-Plane Page Program|80h---11h|81h---10h||
|Copy-Back Program|85h|10h||
|Two-Plane Copy-Back Program|85h---11h|81h---10h||
|Block Erase|60h|D0h||
|Two-Plane Block Erase|60h---60h|D0h||
|Random Data Input|85h|-||
|Random Data Output|05h|E0h||
|Read Status|70h||O|
|Read Status 2|F1h||O|

1. Read     
	发送命令00h, 发送5个Cycle的地址(1st/2st Cycle为列地址, 3,4,5为行地址)，发送命令30h, 之后Nand Flash的R/nB信号线变为低电平(Busy), 为读取数据。读取出数据后，变为高电平(Ready).之后通过不断拉低nRE(读信号使能)，从I/O口读出数据; 从I/O口读数据期间，如果拉高nCE使能信号引脚，则I/O引脚不再发送数据;
	
2. Random Data Output
	* 00h
	* Column Address + Row Address
	* 30h
	* Waitting for R/nB
	* I/O口开始发送数据
	* 05h
	* Column Address
	* E0h
	* I/O口从特定列地址位置发送数据
	
3. Page Program
	* 80h
	* Column Address + Row Address
	* 1 up to m Byte Data (Serial input from I/O0~7)
	* 10h
	* waitting for R/nB Ready.
	* 70h
	* Read I/O 0 (IO0 = 0, Successful Program; IO0 = 1, Error in Program)

	先通过80h-地址-数据-10h写数据（最多一页528Bytes), 然后通过70h读状态;状态位通过I/O 0表示。
	
4. Copy-Back Program    
	Copy-Back功能，将一页数据拷贝到另一页中（不需要从Nand Flash中拷贝出来到SDRAM，再写到另一页；而是直接读取数据到内部的页寄存器Page Register, 然后写到新的页中。)     
	* 00h
	* Column Address + Row Address
	* 35h ( 00h-35h, Read for Copy Back)
	* 数据写入内部的Page Register
	* 85h
	* Column Address + Row Address
	* 从Page Register中读出数据
	* 10h
	* Waitting for R/nB to Ready
	* 70h
	* Read IO0 Status.



## 代码详解

&emsp;功能与SDRANAndMMU下的函数相同，为测试nand的使用，将程序编译大小超过8K，无法利用板子固化在ROM中因此需要start.s将程序从nand flash中拷贝到sdram中，然后跳转到sdram中运行。  
&emsp;这里复制了nand的初始化程序和拷贝程序，自己编写将代码从nand flash中拷贝到sdram的程序，放置在nand.c中。
&emsp;为调试方便，将串口部分程序拷贝过来

## ISSUE

1、忘记修改中.text段，没有把新添加的nand.o,uart.o添加到代码段中。由于start.s需要跳转到nand.c中的函数，而最后连接的文件没有这部分函数，所以出现问题。添加后灯可以正常点亮。

## 要避免覆盖readme

&emsp;copy 自 SeanXP(^o^)

后记：   
`$ cp -r xxx/dirs/ .`   
`$ cp -r xxx/dirs/. .`   
这两行命令不一样啊！    
手抖多敲了一个'/'啊！   
于是readme.md文件就被覆盖掉了啊！   


	

曾经有一份写好的文档放在我面前，   
我没有备份，   
等我覆盖的时候我才后悔莫及，   
人世间最痛苦的事莫过于此。      
如果上天能够给我一个再来一次的机会，   
我会为那份文档输入三个指令：   
git pull   
git commit -m “good doc”   
git push   
如果非要在这个代码上加上一个长注释，   
我希望是...  
“天堂有路你不走，Code无涯苦作舟”  

