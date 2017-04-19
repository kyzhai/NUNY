ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := audio_emulator.o vga_led.o 

else

# We are being compiled as a module: use the Kernel build system
	KERNEL_SOURCE := /usr/src/linux
        PWD := $(shell pwd)

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules


CC:=gcc
DEFS:=-D_ENABLE_TILT -D_ENABLE_FORCE 
CFLAGS:=-Wall -pipe $(DEFS) -g -O9 -Os
INCLUDES:=-I./src
LIBS:=-L./lib -lcwiimote -lbluetooth -lm

all: main.o wiicontroller.o gamelogic.o
	$(CC) $(CFLAGS) -o main $^ $(LIBS) $(INCLUDES)

main.o: main.c wiicontroller.h vga_led.h audio_emulator.h configuration.h
	$(CC) $(CFLAGS) $(INCLUDES) -c $< 

wiicontroller.o: wiicontroller.c configuration.h
	$(CC) $(CFLAGS) $(INCLUDES) -c $< 

gamelogic.o: gamelogic.c gamelogic.h wiicontroller.h configuration.h
	$(CC) $(CFLAGS) $(INCLUDES) -c $<

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} main 

socfpga.dtb : socfpga.dtb
	dtc -O dtb -o socfpga.dtb socfpga.dts

endif 
