U-Boot
====

* mini2440_U-boot使用移植手册.pdf    
	U-Boot 使用及移植详细手册
* U-boot综述与源码分析.pdf
* bin, u-boot.bin文件
* Makefile(u-boot-1.1.6), Makefile文件分析

		mini6410_nand_config-ram256 :  unconfig
    		@$(MKCONFIG) mini6410 arm s3c64xx mini6410 samsung s3c6410 NAND ram256
    		
* mkconfig, 脚本mkconfig分析

# u-boot学习记录

记录环境配置和u-boot学习其间的一些内容 

## 环境搭建

&emsp;运行u-boot需要上位机配置一些环境，首先应该是交叉编译链，但是在裸机部分已经有过说明，这里从tftp和nfs的上位机开始。

&emsp;环境ubuntu 14.04

配置环境是防火墙总是一个问题，运行 sudo ufw  disable 命令关闭Linux防火墙。

### 安装配置TFTP

&emsp;参照**mini2440_U-boot使用移植手册**方法存在一些问题，所以在这里说明方法。

* 安装tftp-hpa（是客户端）、tftpd-hpa（服务端）  
* 修改 /etc/default/tftpd-hpa  如下

```
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="你的tftp目录"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="-l -c -s"
```

* 根据配置文件的路径，建立tftp目录，并修改目录权限；

$sudo chmod 777 你的tftp目录

* 重启tftp服务；

$sudo /etc/init.d/tftpd-hpa restart

* 本地传输测试。

在你的tftp目录下创建个文件test  

执行  
$ tftp 你的主机地址
tftp>?    获取tftp命令
tftp>get test    看能否获取对应文件 

* 注释：

网上的解决方案，包含了配置xinetd,但是我这里没有配置还是正常工作的。至于使用守护进程管理tftp是否是必要的，还不能够下结论，可以先按照上述配置，如果不成，可以考虑按下面配置xinetd。

* 如果没有xinetd就下载一个，然后按照下面配置xinet来管理tftp
&emsp;我们这里使用的xinet.d守护进程，是用于替换原有inet.d守护进程的。xinet.d提供与inet.d一直的进本服务，不过还提供数目众多的其他特性，包括根据客户的地址等级，接受或拒绝连接的选项，每个服务一个配置文件的做法等。

  我们使用了xinet.d服务器，将配置过程作为注解放在这里

* 修改配置文件/etc/xinetd.d/tftp；（因为xinet.d是一个服务一个配置文件，如果没有就创建一个）

```
service tftp
{
    disable = no
        socket_type = dgram
        protocol = udp
        wait = yes
        user = root
        server = /usr/sbin/in.tftpd
        server_args = -s -c 你的tftp目录
        per_source = 11
        cps = 100 2
        flags = IPv4
}
```

* 执行下面的命令更新

$ sudo /etc/init.d/xinetd  reload

$ sudo  /etc/init.d/xinetd  restart


### NFS

&emsp;网络文件系统，也称网文系统，板子内核用来通过网络挂载主机上面的文件系统。

* 安装nfs服务器端

$sudo apt-get install nfs-kernel-server

* 安装nfs的客户端：

$sudo apt-get install nfs-common

(在安装nsf-kernel-server的时候，也会安装nfs-commom。如果没有安装这个软件包，则要执行)

* 设置共享的目录

$sudo mkdir 你的目录

* 修改/etc/exports

在最后一行添加：/home/USER/nfs *(rw,sync,no_root_squash,no_subtree_check)
        
注：
    前面那个目录是与nfs服务客户端共享的目录  
    *代表允许所有的网段访问（也可以使用具体的IP）  
    rw：挂接此目录的客户端对该共享目录具有读写权限  
    sync：资料同步写入内存和硬盘   
    no_root_squash：客户机用root访问该共享文件夹时，不映射root用户。  
   root_squash:客户机用root用户访问该共享文件夹时，将root用户映射成匿名用户  
   no_subtree_check：不检查父目录的权限。

* nfs是一个RPC程序，使用它前，需要映射好端口，通过rpcbind设置(rpcbind是一种RPC（远程进程通信）服务，nfs共享时候负责通知客户端，服务器的nfs端口号的。) 

$sudo service rpcbind restart

* 重启nfs服务：

$sudo service nfs-kernel-server restart

* 测试

运行以下命令来显示一下共享出来的目录：

$showmount -e

* 挂载指令

到任意一台服务器中执行挂载指令，则可以将指定ip服务器上的共享路径，挂载到本地。

sudo mount -t nfs ***.***.***.***:/home/USER/nfs /nfs-client/

注释：***.***.***.***是NFS服务器的IP地址


* 如果想开机自动挂载：

把上述指令 sudo mount -t nfs ***.***.***.***:/home/USER/nfs /nfs-clinet/ 写到 /etc/rc.local 文件中。


## 编译u-boot

这里将tekkamanninja的git仓库拷贝过来，放到u-boot-tekkamanninja目录，主要是为了防止tekkamanninja因为整理目录导致连接不正确。

### 编译的问题

### 编译步骤

1、设置交叉编译链

&emsp;主目录下的Makefile的交叉编译链路径没有设置，一般都需要根据自己交叉编译链的实际安装位置进行设置，主要设置两个变量

CROSS_COMPILE = 你的交叉编译链路径  
ARCH = arm

&emsp;注意交叉编译链路径要具体到gcc之前，比如arm-linux-gcc，则生面的CROSS_COMPILE就需要设置到arm-linux-


2、运行编译指令

进入主目录，执行

    make mini6410_config
    make

前者用来对u-boot进行配置，从而在使make命令生成我们制定板子的u-boot。g关于mini6410_config的生成，设计到u-boot移植的问题，如果想要学习u-boot移植的知识请参考doc目录下的文档。

## 生成的文件

### u-boot-nand.bin

u-boot-nand.bin是能够通过nand启动的u-boot程序。将u-boot-nand.bin下载到nand中，然后使用nand启动，就可以启动u-boot。


#### 下载u-boot-nand.bin

这里还是使用和下载裸机程序的方法。

* 先挂载SD卡，将u-boot.bin程序拷贝到images/目录下，并指定为相应的名字（这里的设置参见裸机）可以使用这里的mountSDCopyBin.sh脚本文件，可以直接完成拷贝。

* 将开关拨到SDBOOT，利用SD卡中的程序，将u-boot拷贝到nand。

* 将开关拨到nand启动程序，此时运行的就是u-boot

也可以使用SDBOOT的方法

**SDBOOT启动U-Boot，通过NFS烧录U-Boot到NAND Flash:**

1. 搭建NFS服务器，目录:  10.42.1.100:/var/nfsroot/arm/
2. SDBOOT启动U-Boot

		MINI6410 # nfs 50008000 10.42.1.100:/var/nfsroot/arm/u-boot-nand.bin
		dm9000 i/o: 0x18000300, id: 0x90000a46
		DM9000: running in 16 bit mode
		MAC: 08:08:10:12:10:27
		operating at 100M full duplex mode
		Using dm9000 device
		File transfer via NFS from server 10.42.1.100; our IP address is 10.42.1.70
		Filename '/var/nfsroot/arm/u-boot-nand.bin'.
		Load address: 0x50008000
		Loading: 	###################################################
		doen
		Bytes transferred = 259672 (3f658 hex)
3. 烧写进Nand Flash

		MINI6410 # nand erase 0x0 0x80000
		NAND erase: device 0 offset 0x0, size 0x80000
		Erasing at 0x60000 -- 100% complete.
		OK
		
		MINI6410 # nand write 50008000 0 0x80000
		NAND write: device 0 offset 0x0, size 0x80000
		524288 bytes written: OK
		


### u-boot-mmc.bin

mmc_spl/u-boot-spl-16k.bin   
u-boot.bin  

U-boot因为在配置文件中已定义:

	#define MMC_UBOOT_POS_BACKWARD            (0x300000)
	#define MMC_ENV_POS_BACKWARD            (0x280000)
	#define MMC_BACKGROUND_POS_BACKWARD        (0x260000)

* mmc_spl/u-boot-spl-16k.bin烧写到BL1区（第一级引导，代码自拷贝部分）。
* u-boot.bin烧写到BL2（SD卡末尾向前3MB的位置）（0x300000）
* ENV的位置是在SD卡末尾向前2.5MB的位置（在BL2后0.5MB）（0x280000）
* 背景图片的位置在SD卡末尾向前0x260000的位置。
* 一般只需要烧写mmc_spl/u-boot-spl-16k.bin与u-boot.bin即可。

SD卡 - BL1在倒数第二个扇区, 假设总扇区数目为$(total_sectors):  

**mmc_spl写入扇区地址: write_addr = $(total_sectors) - 18;** 

	# dd if=mmc_spl/u-boot-spl-16k.bin of=/dev/sdb seek=write_addr bs=512;
实际运行时需要替换相应数字;

**u-boot.bin写入扇区地址: write_addr = $(total_sectors) - 6144 sectors (3MB);**

对于SDHC卡，最后的1024扇区是不识别的。
$(total_sector) = $(true_sector) - 1024;

eg. 

	Disk /dev/sdb: 7.4 GiB, 7948206080 bytes, 15523840 sectors

	u-boot-spl-16k.bin:
	15523840 - 1024 - 18 = 15522798 sectors
	u-boot.bin:
	15523840 - 1024 - 6144(3MB) = 15516672 sectors = 7944536064 bytes

`#sudo dd if=u-boot-spl-16k.bin of=/dev/sdb seek=15522798 bs=512`   
`#sudo dd if=u-boot.bin of=dev/sdb seek=7944536064 bs=1`   

dd具有扇区与字节的写入方式。


## 熟悉u-boot命令

请阅读mini2440_U-boot使用和移植手册。

### 常用的几个命令

* tftp addr1 serverip:filename      //表示从主机的tftp目录下，下载filename文件

例子：tftp 0x50008000 10.42.1.248:uImage

* nand erase offsetaddr size    //擦除offsetaddr开始处nand的size大小的数据

例子：nand erase 0x80000 0x500000

* nand write srcaddr destaddr size  //表示将源地址大小为size的数据写到nand中，偏移为目的地址指定处

例子：nand write 0x50008000 0x80000 0x500000

* setenv saveenv printenv


## 内核相关的操作

### mkimage

&emsp;mkimage是编译u-boot时产生的一个程序。u-boot加载的内核要事先使用mkimage处理，然后使用bootm等内核引导命令来启动内核。因为，在bootm命令引导内核的时候，bootm需要读取一个64字节的文件头，来获取这个内核映像所针对的CPU体系结构，OS，加载到内存中的位置，在内存中的入口点等信息。这样bootm才能为OS设置好启动环境，并跳入内核的入口点。mkimage就是添加这个文件头的工具。

&emsp;有关mkimage的具体用法参照../kernel目录下的相关说明。

### bootargs

u-boot向内核传递的参数，参见bootargs目录下的readme.md

## u-boot源码分析

&emsp;这部分工作在之前做过，参见本目录下的doc目录下的u-boot源码分析.doc。

## u-boot移植

请参考doc下面的文件**mini2440_U-boot使用移植手册.pdf**。
