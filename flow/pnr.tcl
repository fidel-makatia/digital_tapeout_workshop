# ============================================================================
# OpenROAD Place & Route Script - SKY130
# ============================================================================
# Performs placement, CTS, routing, and generates final DEF/GDS.
#
# Usage: openroad -exit flow/pnr.tcl
# Prerequisite: Floorplan completed (outputs/floorplan.def exists)
# ============================================================================

# ---- Read technology ----
read_lef $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef
read_lef $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd_merged.lef

# ---- Read liberty for timing ----
read_liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ---- Read design ----
read_def outputs/floorplan.def

# ---- Read timing constraints ----
read_sdc constraints/sky130.sdc

# ---- Global Placement ----
puts "Running global placement..."
global_placement -density 0.6

# ---- Detailed Placement ----
puts "Running detailed placement..."
detailed_placement

# ---- Check placement ----
check_placement

# ---- Clock Tree Synthesis ----
puts "Running clock tree synthesis..."
clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_4 \
    -buf_list sky130_fd_sc_hd__clkbuf_4 \
    -sink_clustering_enable

# ---- Repair clock nets ----
repair_clock_nets

# ---- Post-CTS optimization ----
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing

# ---- Global Routing ----
puts "Running global routing..."
global_route -guide_file outputs/route.guide \
    -congestion_iterations 30

# ---- Detailed Routing ----
puts "Running detailed routing..."
detailed_route \
    -output_drc outputs/route_drc.rpt \
    -output_maze outputs/maze.log \
    -bottom_routing_layer met1 \
    -top_routing_layer met5

# ---- Post-route optimization ----
estimate_parasitics -global_routing

# ---- Timing report ----
report_timing -path_delay min_max -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3
report_wns
report_tns

# ---- Write outputs ----
write_def outputs/routed.def
write_verilog outputs/routed_netlist.v

puts ""
puts "============================================================"
puts "  Place & Route Complete!"
puts "  Routed DEF: outputs/routed.def"
puts "  Routed Netlist: outputs/routed_netlist.v"
puts "============================================================"
