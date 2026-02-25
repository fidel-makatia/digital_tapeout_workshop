# ============================================================================
# Yosys Synthesis Script - SKY130
# ============================================================================
# Synthesizes the 8-bit MCU RTL to SKY130 standard cells.
#
# Usage: yosys -s flow/synth.tcl
#
# Prerequisite: SKY130 PDK installed
#   export PDK_ROOT=/path/to/skywater-pdk
# ============================================================================

# ---- Read RTL ----
read_verilog rtl/core/alu.v
read_verilog rtl/core/regfile.v
read_verilog rtl/core/control.v
read_verilog rtl/core/program_rom.v
read_verilog rtl/gpio.v
read_verilog rtl/soc_top.v

# ---- Elaborate ----
hierarchy -check -top soc_top

# ---- Synthesis ----
# Generic synthesis
proc
flatten
opt
fsm
opt
memory
opt
techmap
opt

# ---- Technology mapping to SKY130 ----
# Use sky130_fd_sc_hd (high density) standard cell library
dfflibmap -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- Clean up ----
opt_clean -purge

# ---- Reports ----
stat -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- Write output ----
write_verilog -noattr outputs/netlist.v
write_json outputs/netlist.json

# ---- Print summary ----
tee -o outputs/synth_report.txt stat
