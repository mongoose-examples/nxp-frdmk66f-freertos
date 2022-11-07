PROG = firmware

PROJECT_ROOT_PATH = $(realpath $(CURDIR)/../..)
DOCKER ?= docker run --rm -v $(PROJECT_ROOT_PATH):$(PROJECT_ROOT_PATH) -w $(CURDIR) mdashnet/armgcc

MONGOOSE_FLAGS = -DMG_ARCH=MG_ARCH_FREERTOS -DMG_ENABLE_LWIP=1
MCU_DEFINES =  -DCPU_MK66FN2M0VMD18 -DCPU_MK66FN2M0VMD18_cm4 -DUSE_RTOS=1 -DPRINTF_ADVANCED_ENABLE=1 -DFRDM_K66F -DFREEDOM -DLWIP_DISABLE_PBUF_POOL_SIZE_SANITY_CHECKS=1 -DSERIAL_PORT_TYPE_UART=1 -DSDK_OS_FREE_RTOS -DMCUXPRESSO_SDK -DSDK_DEBUGCONSOLE=1 -DCR_INTEGER_PRINTF -DPRINTF_FLOAT_ENABLE=0 -D__MCUXPRESSO -D__USE_CMSIS -DDEBUG -D__NEWLIB__
MCU_FLAGS = -fno-common -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fmerge-constants -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -fstack-usage -specs=nano.specs
CFLAGS = -std=gnu99 -Os -g3 $(MONGOOSE_FLAGS) $(MCU_DEFINES) $(MCU_FLAGS)

SOURCES = $(shell find $(CURDIR) -type f -name '*.c')
OBJECTS = $(SOURCES:%.c=build/%.o)

INCLUDES = $(addprefix -I, $(shell find $(CURDIR) -type d -not -name 'build'))

LINKFLAGS = -nostdlib -Xlinker --gc-sections -Xlinker -print-memory-usage -Xlinker --sort-section=alignment -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -u _printf_float -u _scanf_float

all:
	$(info $(INCLUDES))

build: $(PROG).bin

$(PROG).bin: $(PROG).axf
	$(DOCKER) arm-none-eabi-size $<
	$(DOCKER) arm-none-eabi-objcopy -v -O binary $< $@

$(PROG).axf: $(OBJECTS)
	$(info LD $@)
	$(DOCKER) arm-none-eabi-gcc $(LINKFLAGS) -T"frdmk66f-freertos.ld" -L"./ld" $(OBJECTS) -o $@

build/%.o: %.c
	@mkdir -p $(dir $@)
	$(info CC $<)
	@$(DOCKER) arm-none-eabi-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf build/ firmware.axf firmware.bin
