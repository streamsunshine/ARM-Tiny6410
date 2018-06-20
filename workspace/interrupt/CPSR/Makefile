# 使用交叉编译链编译程序，已将交叉编译链路径添加到/etc/environment文件中，否则需要指定其路径
# gcc需要使用-nostdlib选项，作用是不连接系统标准启动文件和标准库文件，只将指定的文件传递给连接器。因为这里编译的是裸机程序，我们自己提供了启动文件，所以不需要连接。如果不加上这个选项，系统默认会添加，会报undefined reference to `__aeabi_unwind_cpp_pr0'错。

CPATH = arm-none-linux-gnueabi-
CC = ${CPATH}gcc
LD = ${CPATH}ld
CP = ${CPATH}objcopy
DUMP = ${CPATH}objdump
CFLAGS = -c -nostdlib
LDFLGS = -T cpsr.lds 

OBJECT = led
objs = start.o main.o clock.o sdram.o mmu.o uart.o

$(OBJECT).bin : $(objs) 
	${LD} ${LDFLGS} -o ${OBJECT}.elf $^
	${CP} -O binary -S ${OBJECT}.elf ${OBJECT}.bin
	${DUMP} -D ${OBJECT}.elf > ${OBJECT}.dis

%.o : %.s
	${CC} ${CFLAGS} -o $@ $<

%.o : %.c
	${CC} ${CFLAGS} -o $@ $<

clean:
	rm *.o *.bin *.elf *.dis
