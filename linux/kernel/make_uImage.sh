#################################################################
#   Copyright (C) 2016 Sean Guo. All rights reserved.
#														  
#	> File Name:        < make_uImage.sh >
#	> Author:           < Sean Guo >		
#	> Mail:             < iseanxp+code@gmail.com >		
#	> Created Time:     < 2016/02/24 >
#	> Last Changed:     < 2018/08/03 > 
#	> Description:      将编译好的vmlinux制作为uboot启动的uImage;
#################################################################

#!/bin/bash
/home/max/tiny6410/arm-2014.05/bin/arm-none-linux-gnueabi-objcopy -O binary -R .note -R .comment -S vmlinux linux.bin
gzip -9 linux.bin
./mkimage -A arm -O linux -T kernel -C gzip -a 0x50008000 -e 0x50008000 -n "Linux Kernel Image" -d linux.bin.gz uImage
rm linux.bin.gz
