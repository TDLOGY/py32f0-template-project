# 'make V=1' will show all compiler calls.
V		?= 1
ifeq ($(V),0)
Q		:= @
NULL	:= 2>/dev/null
endif

PREFIX		?= $(ARM_TOOCHAIN)/arm-none-eabi-
CC			= $(PREFIX)gcc
AS			= $(PREFIX)as
LD			= $(PREFIX)ld
OBJCOPY		= $(PREFIX)objcopy
# `$(shell pwd)` or `.`, both works
TOP			= .
BDIR		= $(TOP)/$(BUILD_DIR)
ifeq ($(detected_OS),WIN) 
MKDIR  		= -mkdir
MKDIR_NULL 	= 
RMDIR  		= rmdir /s /q
else
MKDIR  		= mkdir -p
MKDIR_NULL	=
RMDIR  		= rm -rf
endif


# Add single c source files to csources
CSOURCES += $(addprefix $(TOP)/, $(CFILES))
# Then assembly source folders and files
ASOURCES += $(addprefix $(TOP)/, $(AFILES))

# Fill object files with c and asm files (keep source directory structure)
OBJS = $(CSOURCES:$(TOP)/%.c=$(BDIR)/%.o)
OBJS += $(ASOURCES:$(TOP)/%.s=$(BDIR)/%.o)
# d files for detecting h file changes
DEPS=$(CSOURCES:$(TOP)/%.c=$(BDIR)/%.d)

# Arch and target specified flags
ARCH_FLAGS	:= -mthumb -mcpu=cortex-m0plus
# Debug options, -gdwarf-2 for debug, -g0 for release 
# https://gcc.gnu.org/onlinedocs/gcc-12.2.0/gcc/Debugging-Options.html
#  -g: system’s native format, -g0:off, -g/g1,-g2,-g3 -> more verbosely
#  -ggdb: for gdb, -ggdb0:off, -ggdb/ggdb1,-ggdb2,-ggdb3 -> more verbosely
#  -gdwarf: in DWARF format, -gdwarf-2,-gdwarf-3,-gdwarf-4,-gdwarf-5
DEBUG_FLAGS ?= -gdwarf-3

# c flags
OPT			?= -O3
CSTD		?= -std=c99
TGT_CFLAGS 	+= $(ARCH_FLAGS) $(DEBUG_FLAGS) $(OPT) $(CSTD) $(addprefix -D, $(LIB_FLAGS)) -Wall -ffunction-sections -fdata-sections

# asm flags
TGT_ASFLAGS += $(ARCH_FLAGS) $(DEBUG_FLAGS) $(OPT) -Wa,--warn

# ld flags
TGT_LDFLAGS += $(ARCH_FLAGS) -specs=nano.specs -specs=nosys.specs -static -lc -lm \
				-Wl,-Map=$(BDIR)/$(PROJECT).map \
				-Wl,--gc-sections \
				-Wl,--print-memory-usage \
				-Wl,--no-warn-rwx-segments

ifeq ($(ENABLE_PRINTF_FLOAT),y)
TGT_LDFLAGS	+= -u _printf_float
endif

# include paths
TGT_INCFLAGS := $(addprefix -I $(TOP)/, $(INCLUDES))


.PHONY: all clean flash echo

all: $(BDIR)/$(PROJECT).elf $(BDIR)/$(PROJECT).bin $(BDIR)/$(PROJECT).hex

# for debug
echo:
	$(info 1. $(AFILES))
	$(info 2. $(ASOURCES))
	$(info 3. $(CSOURCES))
	$(info 4. $(OBJS))
	$(info 5. $(TGT_INCFLAGS))

# include d files without non-exist warning
-include $(DEPS)

# Compile c to obj -- should be `$(BDIR)/%.o: $(TOP)/%.c`, but since $(TOP) is base folder so non-path also works
$(BDIR)/%.o: %.c
	@echo "CC    $<"
	@$(MKDIR) "$(dir $@)" $(MKDIR_NULL)
	$(Q)$(CC) $(TGT_CFLAGS) $(TGT_INCFLAGS) -MT $@ -o $@ -c $< -MD -MF $(BDIR)/$*.d -MP

# Compile asm to obj
$(BDIR)/%.o: %.s
	@echo "AS    $<"
	@$(MKDIR) "$(dir $@)" $(MKDIR_NULL)
	$(Q)$(CC) $(TGT_ASFLAGS) -o $@ -c $<

# Link object files to elf
$(BDIR)/$(PROJECT).elf: $(OBJS) $(TOP)/$(LDSCRIPT)
	@echo "  LD    $@"
	$(Q)$(CC) $(TGT_LDFLAGS) -T$(TOP)/$(LDSCRIPT) $(OBJS) -o $@

# Convert elf to bin
%.bin: %.elf
	@echo "OBJCP BIN    $@"
	$(Q)$(OBJCOPY) -I elf32-littlearm -O binary  $< $@

# Convert elf to hex
%.hex: %.elf
	@echo "OBJCP HEX    $@"
	$(Q)$(OBJCOPY) -I elf32-littlearm -O ihex  $< $@

clean:
	$(RMDIR) "$(BDIR)"

flash:
ifeq ($(FLASH_PROGRM),jlink)
	$(JLINKEXE) -device $(JLINK_DEVICE) -if swd -speed 4000 -JLinkScriptFile $(TOP)/Misc/jlink-script -CommanderScript $(TOP)/Misc/jlink-command
else ifeq ($(FLASH_PROGRM),pyocd)
	$(PYOCD_EXE) erase -t $(PYOCD_DEVICE) --chip --config $(TOP)/Misc/pyocd.yaml
	$(PYOCD_EXE) load $(BDIR)/$(PROJECT).hex -t $(PYOCD_DEVICE) --config $(TOP)/Misc/pyocd.yaml
else
	@echo "FLASH_PROGRM is invalid\n"
endif

erase:
ifeq ($(FLASH_PROGRM),jlink)
	$(JLINKEXE) -device $(JLINK_DEVICE) -if swd -speed 4000 -JLinkScriptFile $(TOP)/Misc/jlink-script -CommanderScript $(TOP)/Misc/jlink-command_erase
else ifeq ($(FLASH_PROGRM),pyocd)
	$(PYOCD_EXE) erase -t $(PYOCD_DEVICE) --chip --config $(TOP)/Misc/pyocd.yaml
else
	@echo "FLASH_PROGRM is invalid\n"
endif