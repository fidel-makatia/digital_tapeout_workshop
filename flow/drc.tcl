# ============================================================================
# DRC, LVS, and GDS Export Script
# ============================================================================
# Uses Magic for DRC and GDS export, netgen for LVS.
#
# Usage: Run individual steps via Makefile targets:
#   make drc
#   make lvs
#   make gds
# ============================================================================

# ---- Magic DRC Script ----
# Save this as flow/drc.tcl
# Usage: magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc < flow/drc.tcl

puts "Loading design for DRC..."

# Read GDS
gds read outputs/chip.gds

# Load top cell
load soc_top

# Run DRC
drc check
drc catchup

# Report
set drc_count [drc count]
puts "============================================================"
puts "  DRC Results"
puts "  Total violations: $drc_count"
puts "============================================================"

if {$drc_count == 0} {
    puts "  >>> DRC CLEAN <<<"
} else {
    puts "  >>> DRC VIOLATIONS FOUND - Review layout <<<"
    drc why
}

# Save DRC report
set fp [open "outputs/drc_report.txt" w]
puts $fp "DRC Report for soc_top"
puts $fp "Total violations: $drc_count"
close $fp

quit
