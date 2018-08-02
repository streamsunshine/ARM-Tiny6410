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

&emsp;运行u-boot需要上位机配置一些环境，首先应该是交叉编译链，但是在逻辑部分已经有过说明，这里从tftp和nfs的上位机开始。

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
