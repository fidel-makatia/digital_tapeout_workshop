# ============================================================================
# OpenROAD Floorplan Script - SKY130
# ============================================================================
# Sets up the chip floorplan for place-and-route.
#
# Usage: openroad -exit flow/floorplan.tcl
# Prerequisite: Synthesis completed (outputs/netlist.v exists)
# ============================================================================

# ---- Read technology ----
read_lef $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef
read_lef $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd_merged.lef

# ---- Read design ----
read_verilog outputs/netlist.v
link_design soc_top

# ---- Read timing constraints ----
read_sdc constraints/sky130.sdc

# ---- Read liberty for timing ----
read_liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- Floorplan ----
# Die area: 300um x 300um (conservative for small design)
# Core area with margins
initialize_floorplan \
    -die_area "0 0 300 300" \
    -core_area "20 20 280 280" \
    -site unithd

# ---- Power grid ----
# VDD and VSS stripes
make_tracks

# ---- Place pins ----
place_pins -hor_layers met3 -ver_layers met2

# ---- Insert tap cells and end caps ----
tapcell \
    -endcap_cpp 2 \
    -distance 14 \
    -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master sky130_fd_sc_hd__decap_4

# ---- Write floorplan DEF ----
write_def outputs/floorplan.def

puts "Floorplan complete. Output: outputs/floorplan.def"
