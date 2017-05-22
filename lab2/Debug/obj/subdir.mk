################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
ASM_SRCS += \
../obj/bootblock.asm \
../obj/kernel.asm \
../obj/kernel_nopage.asm 

O_SRCS += \
../obj/bootblock.o 

OBJS += \
./obj/bootblock.o \
./obj/kernel.o \
./obj/kernel_nopage.o 


# Each subdirectory must supply rules for building sources it contributes
obj/%.o: ../obj/%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: GCC Assembler'
	as  -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


