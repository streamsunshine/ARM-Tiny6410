# 使用交叉编译链编译程序，已将交叉编译链路径添加到/etc/environment文件中，否则需要指定其路径
#

CPATH = arm-none-linux-gnueabi-
CC = ${CPATH}gcc
LD = ${CPATH}ld
CP = ${CPATH}objcopy
DUMP = ${CPATH}objdump
CFLAGS = -c
LDFLGS = -Ttext 0x50000000 

OBJECT = led
src = $(shell ls *.s)
objs = $(patsubst %.s,%.o,$(src))

$(OBJECT).bin : $(objs) 
	${LD} ${LDFLGS} -o ${OBJECT}.elf $^
	${CP} -O binary -S ${OBJECT}.elf ${OBJECT}.bin
	${DUMP} -D ${OBJECT}.elf > ${OBJECT}.dis

%.o : %.s
	${CC} ${CFLAGS} -o $@ $<

clean:
	rm *.o *.bin *.elf *.dis
