# Targets:
#   make test   build and run the SystemVerilog testbench under Verilator
#   make lint   Verilator lint-only pass over the RTL
#   make clean  remove build artefacts

TOP      := tb_uart_rx
RTL_DIR  := rtl
SIM_DIR  := sim
BUILD    := build

RTL      := $(RTL_DIR)/uart_rx.sv
TB       := $(SIM_DIR)/tb_uart_rx.sv

VFLAGS   := -Wall --top-module $(TOP) --binary --timing -j 0

.PHONY: test lint clean

test: $(BUILD)/$(TOP)
	$(BUILD)/$(TOP)

$(BUILD)/$(TOP): $(RTL) $(TB)
	verilator $(VFLAGS) --Mdir $(BUILD) -o $(TOP) $(RTL) $(TB)

lint:
	verilator --lint-only -Wall --top-module uart_rx $(RTL)

clean:
	rm -rf $(BUILD)
