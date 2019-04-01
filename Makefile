BUILDDIR = build

TOOLS = tools

SOURCES += src/app.c

INCLUDES += -Iinclude -I

LIB += lib/c_init.o
LIB += lib/c_manager.o
LIB += lib/c_midi.o
LIB += lib/c_surface.o
LIB += lib/colours.o
LIB += lib/core_cm3.o
LIB += lib/cx_adc.o
LIB += lib/cx_fifo.o
LIB += lib/cx_fifo1k.o
LIB += lib/cx_midi_parser.o
LIB += lib/cx_pad.o
LIB += lib/cx_switch.o
LIB += lib/device_init.o
LIB += lib/main.o
LIB += lib/misc.o
LIB += lib/startup_stm32f10x_md.o
LIB += lib/stm32f10x_adc.o
LIB += lib/stm32f10x_bkp.o
LIB += lib/stm32f10x_dma.o
LIB += lib/stm32f10x_exti.o
LIB += lib/stm32f10x_flash.o
LIB += lib/stm32f10x_gpio.o
LIB += lib/stm32f10x_it.o
LIB += lib/stm32f10x_pwr.o
LIB += lib/stm32f10x_rcc.o
LIB += lib/stm32f10x_spi.o
LIB += lib/stm32f10x_tim.o
LIB += lib/stm32f10x_usart.o
LIB += lib/system_stm32f10x.o
LIB += lib/usb.o
LIB += lib/usb_core.o
LIB += lib/usb_desc.o
LIB += lib/usb_endp.o
LIB += lib/usb_init.o
LIB += lib/usb_int.o
LIB += lib/usb_istr.o
LIB += lib/usb_mem.o
LIB += lib/usb_prop.o
LIB += lib/usb_pwr.o
LIB += lib/usb_regs.o
LIB += lib/usb_sil.o


OBJECTS = $(addprefix $(BUILDDIR)/, $(addsuffix .o, $(basename $(SOURCES))))

# output files
SYX = $(BUILDDIR)/launchpad_pro.syx
ELF = $(BUILDDIR)/launchpad_pro.elf
HEX = $(BUILDDIR)/launchpad_pro.hex
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
	./$(SIMULATOR)
	./$(HEXTOSYX) $(HEX) $(SYX)

# build the tool for conversion of ELF files to sysex, ready for upload to the unit
$(HEXTOSYX):
	$(HOST_GPP) -Ofast -std=c++0x -I./$(TOOLS)/libintelhex/include ./$(TOOLS)/libintelhex/src/intelhex.cc $(TOOLS)/hextosyx.cpp -o $(HEXTOSYX)

# build the simulator (it's a very basic test of the code before it runs on the device!)
$(SIMULATOR):
	$(HOST_GCC) -g3 -O0 -std=c99 -Iinclude $(TOOLS)/simulator.c $(SOURCES) -o $(SIMULATOR)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF): $(OBJECTS) $(LIB)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS) $(LIB)

DEPENDS := $(OBJECTS:.o=.d)

-include $(DEPENDS)

$(BUILDDIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -MMD -o $@ $<

clean:
	rm -rf $(BUILDDIR)
