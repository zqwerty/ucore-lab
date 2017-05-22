#lab1 report

##练习一 理解通过make生成执行文件的过程
###1. 操作系统镜像文件 ucore.img 是如何一步一步生成的?(需要比较详细地解释 Makefile 中每一条相关命令和命令参数的含义,以及说明命令导致的结果）

自顶向下分析生成 ucore.img 需要的文件

**bin/ucore.img**  

* bin/bootblock
	* obj/boot/bootasm.o
	* obj/boot/bootmain.o
	* bin/sign
* bin/kernel
	* tools/kernel.ld 
	* obj/kern/init/init.o 
	* obj/kern/libs/readline.o 
	* obj/kern/libs/stdio.o 
	* obj/kern/debug/kdebug.o 
	* obj/kern/debug/kmonitor.o 
	* obj/kern/debug/panic.o 
	* obj/kern/driver/clock.o 
	* obj/kern/driver/console.o 
	* obj/kern/driver/intr.o 
	* obj/kern/driver/picirq.o 
	* obj/kern/trap/trap.o 
	* obj/kern/trap/trapentry.o 
	* obj/kern/trap/vectors.o 
	* obj/kern/mm/pmm.o  
	* obj/libs/printfmt.o 
	* obj/libs/string.o

	
#### bootasm.o, bootmain.o
```
# makefile
bootfiles = $(call listf_cc,boot)
$(foreach f,$(bootfiles),$(call cc_compile,$(f),$(CC),$(CFLAGS) -Os -nostdinc))
	
# 实际命令由宏生成，编译boot文件夹下的 bootasm.S, bootmain.c 
i386-elf-gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Os -nostdinc -c boot/bootasm.S -o obj/boot/bootasm.o
i386-elf-gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Os -nostdinc -c boot/bootmain.c -o obj/boot/bootmain.o
	
# 参数说明
-I<dir>  添加搜索头文件的路径
-fno-builtin 除非用__builtin_前缀，否则不进行builtin函数的优化
-ggdb  生成可供gdb使用的调试信息
-m32  生成适用于32位环境的代码
-gstabs  生成stabs格式的调试信息。
-fno-stack-protector  不生成用于检测缓冲区溢出的代码
-Os  为减小代码大小而进行优化
-nostdinc  不使用标准库
```
	
---
#### sign
```
# makefile
$(call add_files_host,tools/sign.c,sign,sign)
$(call create_target_host,sign,sign)
	
# 实际命令，编译sign.c生成sign
gcc -Itools/ -g -Wall -O2 -c tools/sign.c -o obj/sign/tools/sign.o
gcc -g -Wall -O2 obj/sign/tools/sign.o -o bin/sign
```
---
####bootblock
```
# makefile
$(bootblock): $(call toobj,$(bootfiles)) | $(call totarget,sign)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 $^ -o $(call toobj,bootblock)
	@$(OBJDUMP) -S $(call objfile,bootblock) > $(call asmfile,bootblock)
	@$(OBJDUMP) -t $(call objfile,bootblock) | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,bootblock)
	@$(OBJCOPY) -S -O binary $(call objfile,bootblock) $(call outfile,bootblock)
	@$(call totarget,sign) $(call outfile,bootblock) $(bootblock)
	
# 实际命令
# 生成bootblock.o
i386-elf-ld -m    elf_i386 -nostdlib -N -e start -Ttext 0x7C00 obj/boot/bootasm.o obj/boot/bootmain.o -o obj/bootblock.o
-m <emulation>  模拟为i386上的连接器
-nostdlib  不使用标准库
-N  设置代码段和数据段均可读写
-e <entry>  指定入口
-Ttext  制定代码段开始位置
	
# 拷贝bootblock.o到bootblock.out
objcopy -S -O binary obj/bootblock.o obj/bootblock.out
-S  移除所有符号和重定位信息
-O <bfdname>  指定输出格式
	
# 运行sign，用bootblock.out生成bootblock
bin/sign obj/bootblock.out bin/bootblock
```
---
####obj/libs/\*.o & obj/kern/\*/\*.o 
```
# makefile
$(call add_files_cc,$(call listf_cc,$(LIBDIR)),libs,)
$(call add_files_cc,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))
	
# 实际命令(各举一例)
# 编译libs/printfmt.c
i386-elf-gcc -Ilibs/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/  -c libs/printfmt.c -o obj/libs/printfmt.o
# 编译kern/init/init.c
i386-elf-gcc -Ikern/init/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/init/init.c -o obj/kern/init/init.o
```
---
####kernel
```
# makefile
$(kernel): tools/kernel.ld
$(kernel): $(KOBJS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS)
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)
	
# 实际命令，使用kernel.ld脚本，生成kernel
i386-elf-ld -m    elf_i386 -nostdlib -T tools/kernel.ld -o bin/kernel \
 obj/kern/init/init.o obj/kern/libs/readline.o obj/kern/libs/stdio.o \ 
 obj/kern/debug/kdebug.o obj/kern/debug/kmonitor.o obj/kern/debug/panic.o \ 
 obj/kern/driver/clock.o obj/kern/driver/console.o obj/kern/driver/intr.o \
 obj/kern/driver/picirq.o obj/kern/trap/trap.o obj/kern/trap/trapentry.o \ 
 obj/kern/trap/vectors.o obj/kern/mm/pmm.o  obj/libs/printfmt.o \
 obj/libs/string.o
	
# 参数说明
-T <scriptfile>  让连接器使用指定的脚本

```
---
####ucore.img
```
# makefile
UCOREIMG	:= $(call totarget,ucore.img)
$(UCOREIMG): $(kernel) $(bootblock)
	$(V)dd if=/dev/zero of=$@ count=10000
	$(V)dd if=$(bootblock) of=$@ conv=notrunc
	$(V)dd if=$(kernel) of=$@ seek=1 conv=notrunc
$(call create_target,ucore.img)
	
# 实际命令
# 生成一个有10000个块的文件，每个块默认512字节，用0填充
dd if=/dev/zero of=bin/ucore.img count=10000
# 把bootblock中的内容写到第一个块
dd if=bin/bootblock of=bin/ucore.img conv=notrunc
# 从第二个块开始写kernel中的内容
dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrunc
```

###2. 一个被系统认为是符合规范的硬盘主引导扇区的特征是什么?  
结合原理课和sign.c的代码，一个磁盘主引导扇区大小为512字节。且最后两个字节是0x55AA。

	
##练习二 使用qemu执行并调试lab1中的软件
###1. 从CPU加电后执行的第一条指令开始，单步跟踪BIOS的执行。

0. 参考附录“启动后第一条执行的指令”
1. 修改 lab1/tools/gdbinit,
	
	```
	set architecture i8086 
	target remote :1234
	```
2. lab1目录下，执行`make debug`，进入gdb
3. 在gdb中执行`si`命令进行单步跟踪

进入gdb后$pc显示为0xfff0，使用`x /i $pc`查看$pc处指令，发现不是跳转指令而是`add %al,(%bx,%si)`，查看0xffff0处指令`x /i 0xffff0`发现这才是实际的第一条指令。原因是此时$pc实际上是%eip的值，第一条指令的地址是`(CS<<4)|(EIP)=0xffff0`

###2. 在初始化位置0x7c00 设置实地址断点,测试断点正常。

1中gdb启动后，输入`b *0x7c00`即可设置断点，接着执行`c`，就能运行到断点处。


观察到确实停在断点处，查看前十条指令：

```
(gdb) b *0x7c00

###3. 从0x7c00开始跟踪代码运行,将单步跟踪反汇编得到的代码与bootasm.S和 bootblock.asm进行比较。

1. 修改Makefile，在debug命令下调用qemu时加入参数`-d in_asm -D $(BINDIR)/q.log`，将运行的汇编指令保存在`bin/q.log`中
2. 将q.log中`0x00007c00`开始的指令与bootasm.S 和 bootblock.asm进行比较，发现都是相同的


###4. 自己找一个bootloader或内核中的代码位置,设置断点并进行测试

选择`kern_init`函数进行测试，修改gdbinit文件：

```
set architecture i8086
```
即可在make debug命令后进入gdb调试，停在`kern_init`处


##练习三 分析bootloader进入保护模式的过程

通过阅读实验指导书中bootloader启动过程一节和附录中关于A20 Gate的相关内容，结合gdb调试，分析`bootasm.S`源码。源码中已有不少注释，因此在这里只挑关键的步骤讲。

####宏定义

```
.set PROT_MODE_CSEG,        0x8                     

####寄存器初始化


```

####开启A20
为了保持**寻址到超过1MB的内存时,会发生“回卷”**的向下兼容，出现了A20。下面引用[关于A20 Gate](http://hengch.blog.163.com/blog/static/107800672009013104623747/)中的一段话，解释为什么要开启A20 Gate
> 出现80286以后，为了保持和8086的兼容，PC机在设计上在第21条地址线（也就是A20）上做了一个开关，当这个开关打开时，这条地址线和其它地址线一样可以使用，当这个开关关闭时，第21条地址线（A20）恒为0，这个开关就叫做A20 Gate，很显然，在实模式下要访问高端内存区(1M+)，这个开关必须打开，在保护模式下，由于使用32位地址线，如果A20恒等于0，那么系统只能访问奇数兆的内存，即只能访问0--1M、2-3M、4-5M......，这显然是不行的，所以在保护模式下，这个开关也必须打开。

开启A20的方式是向键盘控制器8042发送一个命令来完成。键盘控制器8042将会将它的的某个输出引脚的输出置高电平,作为 A20 地址线控制的输入。
具体步骤：

1. 等待8042 Input buffer为空;

```
####初始化gdt
从引导区中载入一个简单的GDT表和其描述符```lgdt gdtdesc```

```
# Bootstrap GDT
```
####进入保护模式
CR0寄存器最低位置1，进入保护模式

```
```
长跳转，修改CS寄存器的值为PROT\_MODE_CSEG(0x8)

```
```
设置保护模式数据段寄存器，建立堆栈区

```

##练习四 分析bootloader加载ELF格式的OS的过程
分析`bootmain.c`：
####宏定义

```
#define SECTSIZE        512			//扇区大小
####辅助函数
```
	// 读取磁盘IO状态和命令寄存器，判断是否可用
```
####读取扇区内容
读取第secno个扇区到dst

```
static void
    //设置磁盘IO地址寄存器
    //设置LBA参数，设定读取主盘
从偏移量为offset处读取count个字节到地址va中。读取以扇区为单位，因此如果offset不在扇区边界，则完整载入该扇区内容（可能会有多读取的内容）。bootloader在扇区0，因此kernel从扇区1开始

```
```
####加载ELF格式的OS
从磁盘读取ELF头部，解析后得到program header数组的首地址和大小，按照program header的描述将ELF文件中数据载入内存。最后跳转到内核入口执行。

```
void
    
    //按照program header的描述将ELF文件中数据载入内存。
```

##练习五 实现函数调用堆栈跟踪函数 （需要编程）
主要通过`%ebp`寄存器实现函数调用的堆栈跟踪。

- *ebp : 调用者ebp
- *(ebp+4) : 本函数返回地址，即调用时的eip
- *(ebp+8) : 第一个参数
- *(ebp+12) : 第二个参数
- ...

```
void
    //读取当前ebp、eip
    	//记录前四个参数
        //递归跟踪

输出与指导书中大致一致，有部分参数不同但是各个函数名是相同的。

```
ebp:0x00007b38 eip:0x00100a28 args: 0x00010094 0x00010094 0x00007b68 0x0010007f

最后一行`ebp:0x00007bf8`实际上是bootmain的ebp。bootasm中，esp=0x7c00，ebp=0，调用bootmain函数时，返回值和ebp压栈，所以最后一个不为零的ebp=0x7bf8。最后一行的参数则是大于0x7c00地址中的内容。

```
...
0x7c00	Return addr of bootmain
0x7bfc	previous ebp = 0
0x7bf8	ebp of bootmain
...
```

## 练习六 完善中断初始化和处理 （需要编程）
####中断描述符表（也可简称为保护模式下的中断向量表）中一个表项占多少字节？其中哪几位代表中断处理代码的入口？
IDT中一个表项占8个字节，第2、3字节是段选择子，0、1字节和6、7字节可以拼成offset。通过段选择子查找段描述符表，结合offset就能确定中断处理代码的入口。

####请编程完善kern/trap/trap.c中对中断向量表进行初始化的函数idt\_init。在idt\_init函数中，依次对所有中断入口进行初始化。使用mmu.h中的SETGATE宏，填充idt数组内容。每个中断的入口由tools/vectors.c生成，使用trap.c中声明的vectors数组即可。
修改`idt_init`函数：

1. 引入中断入口
2. 填充IDT
3. 加载IDT

```
void
```

####请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写trap函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”。
在`trap_dispatch`中实现对时钟中断的处理。用**ticks**记录时钟中断次数，达到100次时打印，并将ticks归零。


```
static void
    ...
    }
}
```

##与参考答案的区别
####练习一
- 我是从`make V=`产生的编译信息入手，从具体指令出发，分析ucore.img的生成过程，然后在Makefile中找到对应的指令进行分析。而参考答案是从Makefile出发。

####练习二
- 我是在gdb启动后设置断点，而参考答案是在gdbinit中设置断点。

####练习三
- 我解释了为什么要开启A20以及具体如何开启A20，而参考答案语焉不详。

####练习四
- 我具体说明了如何从磁盘读取任意长度的内容。

####练习五
- 实现堆栈跟踪函数时，我是将参数的内容拷贝出来存放到数组里，而参考答案是将数组首地址赋值为`ebp+2`，这种方法省去了拷贝的过程，值得学习。
- 我详细解释了调用bootmain时的栈结构，对输出的最后一行进行说明。

####练习六
- 初始化入口时，我设置的size是256，而参考答案并没有写死，而是用了`sizeof(idt) / sizeof(struct gatedesc)`，这样修改idt大小时就不用再修改初始化的代码了。

##知识点
####列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- Makefile、gdb的简单使用
- BIOS的启动和加电后第一条指令
- bootloader启动过程
	- 实验中增加了开启A20，读取硬盘，加载ELF格式的OS的相关知识。这些都是实际会遇到的问题，原理中没有介绍
	- 实验资料中还介绍了保护模式下的特权级的内容
- 堆栈相关
- 中断初始化和处理
	- 实验中每个中断都会设置errorCode，与原理中有差异，但是实现方便。
	- 实验中还介绍了IDT表项的形式

####列出你认为OS原理中很重要，但在实验中没有对应上的知识点
- GDTR寄存器的使用
- 中断时特权级的转换