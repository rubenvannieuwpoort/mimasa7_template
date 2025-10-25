PROJECT_NAME := main
PROJECT := $(PROJECT_NAME).xpr
TOP_LEVEL_MODULE := main
VIVADO_DIR := /opt/Xilinx/2025.1/Vivado
BITSTREAM_PATH := main.runs/impl_1/$(TOP_LEVEL_MODULE).bit
ABS_BITSTREAM_PATH := $(abspath $(BITSTREAM_PATH))
VIVADO := $(VIVADO_DIR)/bin/vivado -mode batch -nolog -nojournal

PART := xc7a50tfgg484-1
CONSTRAINTS_FILE := mimasa7.xdc
DESIGN_FILES := "$(shell find src -type f -name '*.vhd' -print0 | xargs -0)"
SIM_FILES := "$(shell find sim -type f -name '*.vhd' -print0 2>/dev/null | xargs -0)"


.PHONY: bitstream program clean program_volatile_openocd program_persistent_openocd program_volatile_xc3sprog program_persistent_xc3sprog

bitstream: $(PROJECT)
	PROJECT=$(PROJECT) BITSTREAM_PATH=$(BITSTREAM_PATH) $(VIVADO) -source scripts/bitstream.tcl

main.xpr:
	rm -f $(PROJECT)
	PROJECT_NAME=$(PROJECT_NAME) DESIGN_FILES=$(DESIGN_FILES) SIM_FILES=$(SIM_FILES) TOP_LEVEL_MODULE=$(TOP_LEVEL_MODULE) CONSTRAINTS_FILE=$(CONSTRAINTS_FILE) PART=$(PART) $(VIVADO) -source scripts/create_project.tcl

program: program_volatile_openocd

program_volatile_openocd:
	openocd -f board/numato_mimas_a7.cfg -c "init" -c "pld load 0 $(BITSTREAM_PATH)" -c "shutdown"

program_persistent_openocd:
	openocd -f board/numato_mimas_a7.cfg -c "init" -c "jtagspi_init 0 board/bscan_spi_xc7a50t.bit" -c "jtagspi_program $(BITSTREAM_PATH) 0x00000000"  -c "shutdown"

program_volatile_xc3sprog:
	cd board/xc3sprog && xc3sprog -c mimas_a7 $(ABS_BITSTREAM_PATH)

program_persistent_xc3sprog:
	cd board/xc3sprog && xc3sprog -c mimas_a7 bscan_spi/bscan_mimas_a7_xc7a50tfgg484.bit && xc3sprog -c mimas_a7 -I $(ABS_BITSTREAM_PATH)

clean:
	rm -rf $(PROJECT) .Xil main.cache main.hw main.ip_user_files main.runs main.sim main.srcs
