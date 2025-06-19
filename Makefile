
LIB_DIR := ./libs

OPENOCD_URL := https://github.com/openocd-org/openocd/releases/download/v0.12.0/openocd-v0.12.0-i686-w64-mingw32.tar.gz
OPENOCD := openocd
OPENOCD_SCRIPTS := /usr/share/openocd/scripts
VIVADO_WINDOWS := C:/Xilinx/Vivado/2024.2/bin/vivado
VIVADO_LINUX := /tools/Xilinx/Vivado/2024.2/bin/vivado
VIVADO := $(VIVADO_LINUX)

LOCAL_SCRIPTS := ./openocd
BOARD := zybo-z7-20.cfg

BIT_DIR := bits/blinky
BIT_FILE := bits/blinky/blinky.bit

.PHONY: configure
configure:
	powershell.exe -C "[Void][System.IO.Directory]::CreateDirectory('$(LIB_DIR)')"
	@echo "Download OpenOCD v0.12.0"
	powershell.exe -C "wget $(OPENOCD_URL) -OutFile openocd.tar.gz"
	powershell.exe -C "[Void][System.IO.Directory]::CreateDirectory('$(LIB_DIR)/openocd')"
	powershell.exe -C "tar -xvf openocd.tar.gz -C $(LIB_DIR)/openocd"
	powershell.exe -C "rm openocd.tar.gz"

.PHONY: targets
targets:
	$(OPENOCD) -s $(OPENOCD_SCRIPTS) -s $(LOCAL_SCRIPTS) -s $(BIT_DIR) \
		-f $(BOARD) \
		-c "targets" \
		-c "shutdown" 

.PHONY: program_bit
program_bit: $(BIT_FILE)
	$(OPENOCD) -s $(OPENOCD_SCRIPTS) -s $(LOCAL_SCRIPTS) -s $(BIT_DIR) \
		-f $(BOARD) \
		-c "zynq_program_bit $(abspath $(BIT_FILE));" \
		-c "shutdown"

.PHONY: hello_world
hello_world:
	$(VIVADO) -mode batch -source ./src/tcl/hello_world.tcl

.PHONY: generate-zynq
generate-zynq:
	$(VIVADO) -mode batch -source ./src/tcl/generate-zynq.tcl

.PHONY: computer-board
computer-board:
	$(VIVADO) -mode batch -source ./src/tcl/computer-board.tcl

.PHONY: clean
clean:
	rm -rf ./build
	rm -rf ./.Xil
	rm ./vivado*.jou
	rm ./vivado*.log
	rm ./clockInfo*.txt
