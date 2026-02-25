# ============================================================================
# Digital Tapeout Workshop - Master Makefile
# ============================================================================
# 8-bit Accumulator MCU on SKY130
#
# Prerequisites:
#   - Icarus Verilog (iverilog, vvp)
#   - GTKWave (for waveform viewing)
#   - Yosys (synthesis)
#   - OpenROAD (place & route)
#   - Magic (DRC, GDS export)
#   - netgen (LVS)
#   - SKY130 PDK (set PDK_ROOT environment variable)
#
# Quick Start (simulation only - no PDK needed):
#   make sim          # Run all simulations
#   make wave         # View SoC waveforms in GTKWave
#
# Full Flow (requires SKY130 PDK):
#   make all          # Run complete RTL-to-GDS flow
# ============================================================================

# ---- Configuration ----
PDK_ROOT ?= /opt/skywater-pdk
export PDK_ROOT

# Tool paths (override if not in PATH)
IVERILOG  ?= iverilog
VVP       ?= vvp
GTKWAVE   ?= gtkwave
YOSYS     ?= yosys
OPENROAD  ?= openroad
MAGIC     ?= magic
NETGEN    ?= netgen

# ---- RTL Sources ----
RTL_SRCS = \
    rtl/core/alu.v \
    rtl/core/regfile.v \
    rtl/core/control.v \
    rtl/core/program_rom.v \
    rtl/gpio.v \
    rtl/soc_top.v

# ============================================================================
# Phony targets
# ============================================================================
.PHONY: all sim clean wave help check_tools \
        test_alu test_gpio test_soc \
        synth floorplan pnr gds drc lvs

# ---- Default target ----
all: sim synth floorplan pnr gds drc lvs
	@echo ""
	@echo "============================================================"
	@echo "  COMPLETE: Full RTL-to-GDS flow finished!"
	@echo "  Final GDS: outputs/chip.gds"
	@echo "============================================================"

help:
	@echo "============================================================"
	@echo "  Digital Tapeout Workshop - Available Targets"
	@echo "============================================================"
	@echo ""
	@echo "  Simulation (no PDK needed):"
	@echo "    make sim          - Run all testbenches"
	@echo "    make test_alu     - Run ALU unit tests"
	@echo "    make test_gpio    - Run GPIO unit tests"
	@echo "    make test_soc     - Run full SoC integration test"
	@echo "    make wave         - Open SoC waveforms in GTKWave"
	@echo "    make wave_alu     - Open ALU waveforms in GTKWave"
	@echo ""
	@echo "  Backend Flow (requires SKY130 PDK):"
	@echo "    make synth        - Synthesize RTL to gates"
	@echo "    make floorplan    - Create chip floorplan"
	@echo "    make pnr          - Place and route"
	@echo "    make gds          - Export GDS for fabrication"
	@echo "    make drc          - Run design rule checks"
	@echo "    make lvs          - Run layout vs schematic"
	@echo ""
	@echo "    make all          - Run complete flow"
	@echo "    make clean        - Remove all generated files"
	@echo "    make check_tools  - Verify tool installation"
	@echo "============================================================"

# ============================================================================
# Tool Check
# ============================================================================
check_tools:
	@echo "Checking tool installation..."
	@which $(IVERILOG)  > /dev/null 2>&1 && echo "  [OK] iverilog"  || echo "  [MISSING] iverilog  - Install: apt install iverilog"
	@which $(VVP)       > /dev/null 2>&1 && echo "  [OK] vvp"       || echo "  [MISSING] vvp"
	@which $(GTKWAVE)   > /dev/null 2>&1 && echo "  [OK] gtkwave"   || echo "  [MISSING] gtkwave   - Install: apt install gtkwave"
	@which $(YOSYS)     > /dev/null 2>&1 && echo "  [OK] yosys"     || echo "  [MISSING] yosys     - Install: see https://github.com/YosysHQ/yosys"
	@which $(OPENROAD)  > /dev/null 2>&1 && echo "  [OK] openroad"  || echo "  [MISSING] openroad  - Install: see https://github.com/The-OpenROAD-Project"
	@which $(MAGIC)     > /dev/null 2>&1 && echo "  [OK] magic"     || echo "  [MISSING] magic     - Install: see http://opencircuitdesign.com/magic"
	@which $(NETGEN)    > /dev/null 2>&1 && echo "  [OK] netgen"    || echo "  [MISSING] netgen    - Install: see http://opencircuitdesign.com/netgen"
	@echo ""
	@if [ -d "$(PDK_ROOT)/sky130A" ]; then \
		echo "  [OK] SKY130 PDK found at $(PDK_ROOT)"; \
	else \
		echo "  [MISSING] SKY130 PDK - Set PDK_ROOT env variable"; \
	fi

# ============================================================================
# Simulation Targets
# ============================================================================

sim: test_alu test_gpio test_soc
	@echo ""
	@echo "============================================================"
	@echo "  All simulations complete!"
	@echo "  View waveforms: make wave"
	@echo "============================================================"

# ---- ALU Unit Test ----
test_alu: tb/alu_tb.vcd
tb/alu_tb.vcd: tb/alu_tb.v rtl/core/alu.v
	@echo ""
	@echo "========== ALU Unit Test =========="
	$(IVERILOG) -o tb/alu_tb.out tb/alu_tb.v rtl/core/alu.v
	$(VVP) tb/alu_tb.out
	@echo ""

# ---- GPIO Unit Test ----
test_gpio: tb/gpio_tb.vcd
tb/gpio_tb.vcd: tb/gpio_tb.v rtl/gpio.v
	@echo ""
	@echo "========== GPIO Unit Test =========="
	$(IVERILOG) -o tb/gpio_tb.out tb/gpio_tb.v rtl/gpio.v
	$(VVP) tb/gpio_tb.out
	@echo ""

# ---- SoC Integration Test ----
test_soc: tb/soc_tb.vcd
tb/soc_tb.vcd: tb/soc_tb.v $(RTL_SRCS)
	@echo ""
	@echo "========== SoC Integration Test =========="
	$(IVERILOG) -o tb/soc_tb.out tb/soc_tb.v $(RTL_SRCS)
	$(VVP) tb/soc_tb.out
	@echo ""

# ---- Waveform Viewing ----
wave: tb/soc_tb.vcd
	$(GTKWAVE) tb/soc_tb.vcd &

wave_alu: tb/alu_tb.vcd
	$(GTKWAVE) tb/alu_tb.vcd &

wave_gpio: tb/gpio_tb.vcd
	$(GTKWAVE) tb/gpio_tb.vcd &

# ============================================================================
# Backend Flow Targets
# ============================================================================

# ---- Synthesis ----
synth: outputs/netlist.v
outputs/netlist.v: $(RTL_SRCS) flow/synth.tcl
	@echo ""
	@echo "========== Synthesis (Yosys) =========="
	$(YOSYS) -s flow/synth.tcl 2>&1 | tee outputs/synth.log
	@echo ""

# ---- Floorplan ----
floorplan: outputs/floorplan.def
outputs/floorplan.def: outputs/netlist.v flow/floorplan.tcl constraints/sky130.sdc
	@echo ""
	@echo "========== Floorplan (OpenROAD) =========="
	$(OPENROAD) -exit flow/floorplan.tcl 2>&1 | tee outputs/floorplan.log
	@echo ""

# ---- Place & Route ----
pnr: outputs/routed.def
outputs/routed.def: outputs/floorplan.def flow/pnr.tcl constraints/sky130.sdc
	@echo ""
	@echo "========== Place & Route (OpenROAD) =========="
	$(OPENROAD) -exit flow/pnr.tcl 2>&1 | tee outputs/pnr.log
	@echo ""

# ---- GDS Export ----
gds: outputs/chip.gds
outputs/chip.gds: outputs/routed.def flow/gds_export.tcl
	@echo ""
	@echo "========== GDS Export (Magic) =========="
	$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		< flow/gds_export.tcl 2>&1 | tee outputs/gds.log
	@echo ""

# ---- DRC ----
drc: outputs/chip.gds flow/drc.tcl
	@echo ""
	@echo "========== DRC (Magic) =========="
	$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		< flow/drc.tcl 2>&1 | tee outputs/drc.log
	@echo ""

# ---- LVS ----
lvs: outputs/extracted.spice outputs/routed_netlist.v flow/lvs.tcl
	@echo ""
	@echo "========== LVS (netgen) =========="
	$(NETGEN) -batch lvs flow/lvs.tcl 2>&1 | tee outputs/lvs.log
	@echo ""

# ============================================================================
# Clean
# ============================================================================
clean:
	rm -f tb/*.out tb/*.vcd
	rm -f outputs/netlist.v outputs/netlist.json
	rm -f outputs/synth_report.txt outputs/synth.log
	rm -f outputs/floorplan.def outputs/floorplan.log
	rm -f outputs/routed.def outputs/routed_netlist.v
	rm -f outputs/route.guide outputs/route_drc.rpt outputs/maze.log
	rm -f outputs/pnr.log
	rm -f outputs/chip.gds outputs/gds.log
	rm -f outputs/extracted.spice
	rm -f outputs/drc_report.txt outputs/drc.log
	rm -f outputs/lvs_report.txt outputs/lvs.log
	@echo "Cleaned all generated files."
