# Coreographer - Multi-core RISC-V Build System

.PHONY: all help clean setup gen sim synth lint

# Default configuration
CONFIG ?= configs/default.json
CORES ?= 4

# FuseSoC targets
CORE_NAME = ::coreographer:0.1.0

#==============================================================================
# Help
#==============================================================================
help:
	@echo "Coreographer Build System"
	@echo "========================="
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Initialize FuseSoC and download dependencies"
	@echo "  make gen            - Generate top-level RTL from config"
	@echo ""
	@echo "Simulation:"
	@echo "  make sim            - Run full system simulation (Verilator)"
	@echo "  make sim-core       - Simulate single core wrapper"
	@echo "  make sim-scheduler  - Simulate scheduler only"
	@echo "  make waves          - Open waveform viewer"
	@echo ""
	@echo "Synthesis:"
	@echo "  make synth          - Synthesize for PYNQ-Z2"
	@echo "  make impl           - Full implementation (synth + place & route)"
	@echo "  make program        - Program bitstream to FPGA"
	@echo ""
	@echo "Configuration:"
	@echo "  make config-2core   - Configure for 2 cores"
	@echo "  make config-4core   - Configure for 4 cores (default)"
	@echo "  make config-8core   - Configure for 8 cores"
	@echo ""
	@echo "Verification:"
	@echo "  make lint           - Run linter (Verilator lint-only)"
	@echo "  make verify         - Run all testbenches"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make clean-all      - Remove all generated files"
	@echo "  make info           - Show current configuration"
	@echo ""
	@echo "Variables:"
	@echo "  CONFIG=<path>       - Specify custom config file"
	@echo "  CORES=<n>           - Override number of cores"

#==============================================================================
# Setup and Dependencies
#==============================================================================
setup:
	@echo "[SETUP] Initializing FuseSoC..."
	@mkdir -p build rtl/cores/vexriscv
	@echo "[SETUP] Checking for VexRiscv..."
	@if [ ! -f rtl/cores/vexriscv/VexRiscv.v ]; then \
		echo "[SETUP] VexRiscv not found. Please download from:"; \
		echo "        https://github.com/SpinalHDL/VexRiscv"; \
		echo "        Or generate with SpinalHDL"; \
		echo "        Place VexRiscv.v in rtl/cores/vexriscv/"; \
		exit 1; \
	fi
	@echo "[SETUP] Creating directory structure..."
	@mkdir -p rtl/{core,scheduler,interconnect,common}
	@mkdir -p tb/test_programs
	@mkdir -p constraints
	@mkdir -p scripts/vivado
	@echo "[SETUP] Setup complete!"

#==============================================================================
# Generation
#==============================================================================
gen:
	@echo "[GEN] Generating top-level from $(CONFIG)..."
	python3 scripts/gen_top.py $(CONFIG)

info:
	@echo "Current Configuration:"
	@echo "====================="
	@jq . $(CONFIG)

#==============================================================================
# Simulation
#==============================================================================
sim: gen
	@echo "[SIM] Running full system simulation..."
	fusesoc run --target=sim $(CORE_NAME) \
		--NUM_CORES=$(CORES)

sim-core:
	@echo "[SIM] Simulating core wrapper..."
	fusesoc run --target=sim_core $(CORE_NAME)

sim-scheduler:
	@echo "[SIM] Simulating scheduler..."
	fusesoc run --target=sim_scheduler $(CORE_NAME)

waves:
	@echo "[WAVES] Opening waveform viewer..."
	@if [ -f build/*/sim-verilator/trace.vcd ]; then \
		gtkwave build/*/sim-verilator/trace.vcd &; \
	else \
		echo "[ERROR] No waveform found. Run 'make sim' first."; \
	fi

#==============================================================================
# Synthesis
#==============================================================================
synth: gen
	@echo "[SYNTH] Synthesizing for PYNQ-Z2..."
	fusesoc run --target=synth $(CORE_NAME) \
		--NUM_CORES=$(CORES)

impl: synth
	@echo "[IMPL] Running place & route..."
	@echo "[IMPL] This may take 10-30 minutes..."

program:
	@echo "[PROGRAM] Programming FPGA..."
	@echo "[INFO] Looking for bitstream..."
	@BITSTREAM=$$(find build -name "*.bit" | head -1); \
	if [ -z "$$BITSTREAM" ]; then \
		echo "[ERROR] No bitstream found. Run 'make synth' first."; \
		exit 1; \
	fi; \
	echo "[PROGRAM] Found: $$BITSTREAM"; \
	echo "[PROGRAM] Using Vivado Hardware Manager..."; \
	vivado -mode batch -source scripts/vivado/program.tcl -tclargs $$BITSTREAM

#==============================================================================
# Configuration Presets
#==============================================================================
config-2core:
	@echo "[CONFIG] Switching to 2-core configuration..."
	@echo "Not implemented yet - manually edit $(CONFIG)"

config-4core:
	@echo "[CONFIG] Using default 4-core configuration..."
	@cp configs/default.json $(CONFIG)

config-8core:
	@echo "[CONFIG] Switching to 8-core configuration..."
	@echo "Not implemented yet - manually edit $(CONFIG)"

#==============================================================================
# Verification
#==============================================================================
lint:
	@echo "[LINT] Running Verilator lint..."
	fusesoc run --target=lint $(CORE_NAME)

verify:
	@echo "[VERIFY] Running verification suite..."
	@$(MAKE) sim-core
	@$(MAKE) sim-scheduler
	@$(MAKE) sim

#==============================================================================
# Cleanup
#==============================================================================
clean:
	@echo "[CLEAN] Removing build artifacts..."
	rm -rf build/
	fusesoc clean

clean-all: clean
	@echo "[CLEAN] Removing all generated files..."
	rm -rf build/ .fusesoc/

#==============================================================================
# Utility targets
#==============================================================================
.DEFAULT_GOAL := help
