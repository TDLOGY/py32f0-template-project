##### Project #####

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
    detected_OS := WIN
else
    detected_OS := $(shell uname)  # same as "uname -s"
endif

PROJECT			?= app
# The path for generated files
BUILD_DIR		= Build


##### Options #####

# Use LL library instead of HAL, y:yes, n:no
USE_LL_LIB ?= n
# Enable printf float %f support, y:yes, n:no
ENABLE_PRINTF_FLOAT	?= n
# Build with FreeRTOS, y:yes, n:no
USE_FREERTOS	?= n
# Build with CMSIS DSP functions, y:yes, n:no
USE_DSP			?= n
# Build with Waveshare e-paper lib, y:yes, n:no
USE_EPAPER		?= n
# Programmer, jlink or pyocd
FLASH_PROGRM	?= jlink

##### Toolchains #######

ifeq ($(detected_OS),WIN)     # is Windows_NT on XP, 2000, 7, Vista, 10...
ARM_TOOCHAIN	?= C:/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/12.2 rel1/bin
JLINKEXE		?= C:/Program Files/SEGGER/JLink/JLink
else
ARM_TOOCHAIN	?= /opt/gcc-arm/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi/bin
JLINKEXE		?= /opt/SEGGER/JLink/JLinkExe
endif

# path to JLinkExe
# JLink device type, options:
#   PY32F002AX5, PY32F002X5, 
#   PY32F003X4, PY32F003X6, PY32F003X8, 
#   PY32F030X4, PY32F030X6, PY32F030X7, PY32F030X8
JLINK_DEVICE	?= PY32F030X8
# path to PyOCD, 
PYOCD_EXE		?= pyocd
# PyOCD device type, options: 
# 	py32f002ax5, py32f002x5, 
#   py32f003x4,  py32f003x6, py32f003x8, 
#   py32f030x3,  py32f030x4, py32f030x6, py32f030x7, py32f030x8
#   py32f072xb
PYOCD_DEVICE	?= py32f030x8


##### Paths ############

# Link descript file: py32f002x5.ld, py32f003x6.ld, py32f003x8.ld, py32f030x6.ld, py32f030x8.ld
# LDSCRIPT		= Libraries/LDScripts/py32f030x8.ld
LDSCRIPT		= Libraries/LDScripts/py32f002x5.ld

# Library build flags: 
#   PY32F002x5, PY32F002Ax5, 
#   PY32F003x4, PY32F003x6, PY32F003x8, 
#   PY32F030x3, PY32F030x4, PY32F030x6, PY32F030x7, PY32F030x8, 
#   PY32F072xB
LIB_FLAGS       = PY32F030x8

# C source files (if there are any single ones)
CSOURCES := 
CFILES := 	Libraries/CMSIS/Device/PY32F0xx/Source/system_py32f0xx.c \
			User/main.c \
			User/py32f0xx_it.c \
			User/py32f0xx_hal_msp.c

# ASM single files
AFILES := Libraries/CMSIS/Device/PY32F0xx/Source/gcc/startup_py32f002.s

# Include paths
INCLUDES	:= Libraries/CMSIS/Core/Include \
			Libraries/CMSIS/Device/PY32F0xx/Include \
			User

ifeq ($(USE_LL_LIB),y)
CFILES += 	Libraries/BSP_LL/Src/py32f0xx_bsp_clock.c \
			Libraries/BSP_LL/Src/py32f0xx_bsp_led.c \
			Libraries/BSP_LL/Src/py32f0xx_bsp_printf.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_adc.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_dma.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_gpio.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_lptim.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_rtc.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_usart.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_comp.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_exti.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_i2c.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_pwr.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_spi.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_utils.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_crc.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_flash.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_led.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_rcc.c \
			Libraries/PY32F0xx_LL_Driver/Src/py32f0xx_ll_tim.c		

INCLUDES	+= Libraries/PY32F0xx_LL_Driver/Inc \
		Libraries/BSP_LL/Inc
LIB_FLAGS   += USE_FULL_LL_DRIVER
else

CFILES += 	Libraries/BSP/Src/py32f0xx_bsp_clock.c\
			Libraries/BSP/Src/py32f0xx_bsp_led.c\
			Libraries/BSP/Src/py32f0xx_bsp_printf.c\
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_dma.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_iwdg.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_rtc.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_usart.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_adc.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_exti.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_led.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_rtc_ex.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_wwdg.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_adc_ex.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_flash.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_lptim.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_spi.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_comp.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_gpio.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_pwr.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_tim.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_cortex.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_i2c.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_rcc.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_tim_ex.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_crc.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_irda.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_rcc_ex.c \
			Libraries/PY32F0xx_HAL_Driver/Src/py32f0xx_hal_uart.c

INCLUDES	+= Libraries/PY32F0xx_HAL_Driver/Inc \
		Libraries/BSP/Inc
endif

ifeq ($(USE_FREERTOS),y)
CFILES		+= Libraries/FreeRTOS/croutine.c \
				Libraries/FreeRTOS/list.c \
				Libraries/FreeRTOS/queue.c \
				Libraries/FreeRTOS/tasks.c \
				Libraries/FreeRTOS/timers.c \
				Libraries/FreeRTOS/stream_buffer.c \
				Libraries/FreeRTOS/portable/GCC/ARM_CM0/port.c

CFILES		+= Libraries/FreeRTOS/portable/MemMang/heap_4.c

INCLUDES	+= Libraries/FreeRTOS/include \
			Libraries/FreeRTOS/portable/GCC/ARM_CM0
endif

ifeq ($(USE_DSP),y)
CFILES 		+= Libraries/CMSIS/DSP/Source/BasicMathFunctions/BasicMathFunctions.c \
				Libraries/CMSIS/DSP/Source/BayesFunctions/BayesFunctions.c \
				Libraries/CMSIS/DSP/Source/CommonTables/CommonTables.c \
				Libraries/CMSIS/DSP/Source/ComplexMathFunctions/ComplexMathFunctions.c \
				Libraries/CMSIS/DSP/Source/ControllerFunctions/ControllerFunctions.c \
				Libraries/CMSIS/DSP/Source/DistanceFunctions/DistanceFunctions.c \
				Libraries/CMSIS/DSP/Source/FastMathFunctions/FastMathFunctions.c \
				Libraries/CMSIS/DSP/Source/FilteringFunctions/FilteringFunctions.c \
				Libraries/CMSIS/DSP/Source/InterpolationFunctions/InterpolationFunctions.c \
				Libraries/CMSIS/DSP/Source/MatrixFunctions/MatrixFunctions.c \
				Libraries/CMSIS/DSP/Source/QuaternionMathFunctions/QuaternionMathFunctions.c \
				Libraries/CMSIS/DSP/Source/StatisticsFunctions/StatisticsFunctions.c \
				Libraries/CMSIS/DSP/Source/SupportFunctions/SupportFunctions.c \
				Libraries/CMSIS/DSP/Source/SVMFunctions/SVMFunctions.c \
				Libraries/CMSIS/DSP/Source/TransformFunctions/TransformFunctions.c
INCLUDES	+= Libraries/CMSIS/DSP/Include \
		Libraries/CMSIS/DSP/PrivateInclude
endif

ifeq ($(USE_EPAPER),y)
CDIRS		+= Libraries/EPaper/Lib \
			Libraries/EPaper/Examples \
			Libraries/EPaper/Fonts \
			Libraries/EPaper/GUI

INCLUDES	+= Libraries/EPaper/Lib \
			Libraries/EPaper/Examples \
			Libraries/EPaper/Fonts \
			Libraries/EPaper/GUI
endif

include ./rules.mk
