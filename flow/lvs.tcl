# ============================================================================
# LVS Script using netgen
# ============================================================================
# Compares extracted layout netlist against synthesized gate-level netlist.
#
# Usage: netgen -batch lvs flow/lvs.tcl
# ============================================================================

puts "Running LVS comparison..."

# Compare extracted SPICE netlist from layout vs gate-level netlist
lvs "outputs/extracted.spice soc_top_flat" \
    "outputs/routed_netlist.v soc_top" \
    $::env(PDK_ROOT)/sky130A/libs.tech/netgen/sky130A_setup.tcl \
    outputs/lvs_report.txt

puts ""
puts "============================================================"
puts "  LVS comparison complete."
puts "  Report: outputs/lvs_report.txt"
puts "============================================================"
