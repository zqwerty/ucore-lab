################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../kern/mm/pmm.c 

OBJS += \
./kern/mm/pmm.o 

C_DEPS += \
./kern/mm/pmm.d 


# Each subdirectory must supply rules for building sources it contributes
kern/mm/%.o: ../kern/mm/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


