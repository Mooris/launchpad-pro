NAME = launchpad_pro
BUILDDIR = build

TOOLS = tools

SOURCES += src/app.c

INCLUDES += -Iinclude -I

LIB += lib/c_init.c
LIB += lib/c_manager.c
LIB += lib/c_midi.c
LIB += lib/c_surface.c
LIB += lib/colours.c
LIB += lib/core_cm3.c
LIB += lib/cx_adc.c
LIB += lib/cx_fifo.c
LIB += lib/cx_fifo1k.c
LIB += lib/cx_midi_parser.c
LIB += lib/cx_pad.c
LIB += lib/cx_switch.c
LIB += lib/device_init.c
LIB += lib/main.c
LIB += lib/misc.c
LIB += lib/startup_stm32f10x_md.c
LIB += lib/stm32f10x_adc.c
LIB += lib/stm32f10x_bkp.c
LIB += lib/stm32f10x_dma.c
LIB += lib/stm32f10x_exti.c
LIB += lib/stm32f10x_flash.c
LIB += lib/stm32f10x_gpio.c
LIB += lib/stm32f10x_it.c
LIB += lib/stm32f10x_pwr.c
LIB += lib/stm32f10x_rcc.c
LIB += lib/stm32f10x_spi.c
LIB += lib/stm32f10x_tim.c
LIB += lib/stm32f10x_usart.c
LIB += lib/system_stm32f10x.c
LIB += lib/usb.c
LIB += lib/usb_core.c
LIB += lib/usb_desc.c
LIB += lib/usb_endp.c
LIB += lib/usb_init.c
LIB += lib/usb_int.c
LIB += lib/usb_istr.c
LIB += lib/usb_mem.c
LIB += lib/usb_prop.c
LIB += lib/usb_pwr.c
LIB += lib/usb_regs.c
LIB += lib/usb_sil.c


OBJECTS = $(addprefix $(BUILDDIR)/, $(addsuffix .o, $(basename $(SOURCES))))
LIBOBJECTS = $(addprefix $(BUILDDIR)/, $(addsuffix .o, $(basename $(LIB))))

# output files
SYX = $(BUILDDIR)/$(NAME).syx
ELF = $(BUILDDIR)/$(NAME).elf
HEX = $(BUILDDIR)/$(NAME).hex
HEXTOSYX = $(BUILDDIR)/hextosyx
SIMULATOR = $(BUILDDIR)/simulator

# tools
HOST_GPP = g++
HOST_GCC = gcc
CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

CFLAGS  = -Os -Wall -I.\
-D_STM32F103RBT6_  -D_STM3x_  -D_STM32x_ -mthumb -mcpu=cortex-m3 \
-fsigned-char  -DSTM32F10X_MD -DUSE_STDPERIPH_DRIVER -DHSE_VALUE=6000000UL \
-DCMSIS -DUSE_GLOBAL_CONFIG -ffunction-sections -std=c99  -mlittle-endian \
$(INCLUDES) -o

LDSCRIPT = stm32_flash.ld

LDFLAGS += -T$(LDSCRIPT) -u _start -u _Minimum_Stack_Size  -mcpu=cortex-m3 -mthumb -specs=nano.specs -specs=nosys.specs -nostdlib -Wl,-static -N -nostartfiles -Wl,--gc-sections

all: $(SYX)

# build the final sysex file from the ELF - run the simulator first
$(SYX): $(HEX) $(HEXTOSYX) $(SIMULATOR)
	@echo "[\e[34m$(NAME)\e[39m] : [R] \e[94m$(SIMULATOR)\e[39m:"
	@./$(SIMULATOR)
	@echo "[\e[34m$(NAME)\e[39m] : [R] \e[94m$(HEXTOSYX)\e[39m \e[32m$(HEX) $(SYX)\e[39m:"
	@./$(HEXTOSYX) $(HEX) $(SYX)

# build the tool for conversion of ELF files to sysex, ready for upload to the unit
$(HEXTOSYX):
	@echo "[\e[34m$(NAME)\e[39m] : [L] \e[94m$(HEXTOSYX)\e[39m"
	@$(HOST_GPP) -Ofast -std=c++0x -I./$(TOOLS)/libintelhex/include ./$(TOOLS)/libintelhex/src/intelhex.cc $(TOOLS)/hextosyx.cpp -o $(HEXTOSYX)

# build the simulator (it's a very basic test of the code before it runs on the device!)
$(SIMULATOR):
	@echo "[\e[34m$(NAME)\e[39m] : [L] \e[94m$(SIMULATOR)\e[39m"
	@$(HOST_GCC) -g3 -O0 -std=c99 -Iinclude $(TOOLS)/simulator.c $(SOURCES) -o $(SIMULATOR)

$(HEX): $(ELF)
	@echo "[\e[34m$(NAME)\e[39m] : [L] \e[94m$(HEX)\e[39m"
	@$(OBJCOPY) -O ihex $< $@

$(ELF): $(OBJECTS) $(LIBOBJECTS)
	@echo "[\e[34m$(NAME)\e[39m] : [L] \e[94m$@\e[39m"
	@$(LD) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBOBJECTS)

DEPENDS := $(OBJECTS:.o=.d) $(LIBOBJECTS:.o=.d)

-include $(DEPENDS)

$(BUILDDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "[\e[34m$(NAME)\e[39m] : [C] \e[94m$<\e[39m -> \e[32m$@\e[39m"
	@$(CC) -c $(CFLAGS) -MMD -o $@ $<

$(BUILDDIR)/lib/%.o: lib/%.o
	@mkdir -p $(dir $@)
	@echo "[\e[34m$(NAME)\e[39m] : [M] \e[94m$<\e[39m -> \e[32m$@\e[39m"
	@cp $< $@


clean:
	@echo "[\e[34m$(NAME)\e[39m] : [RM] \e[94m$(BUILDDIR)\e[39m"
	@rm -rf $(BUILDDIR)

help:
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94mColor Code\e[39m:"
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94m	[C]  == Compiling\e[39m"
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94m	[L]  == Linking\e[39m"
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94m	[M]  == Move\e[39m"
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94m	[R]  == Run\e[39m"
	@echo "[\e[34m$(NAME)\e[39m] : [Help] \e[94m	[RM] == Remove\e[39m"

.PHONY: all clean
