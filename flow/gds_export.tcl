# ============================================================================
# GDS Export Script using Magic
# ============================================================================
# Converts routed DEF to final GDS for fabrication.
#
# Usage: magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc < flow/gds_export.tcl
# ============================================================================

puts "Exporting GDS..."

# Read LEF
lef read $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef
lef read $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd_merged.lef

# Read routed DEF
def read outputs/routed.def

# Load top cell
load soc_top

# Flatten for GDS export
flatten soc_top_flat
load soc_top_flat

# Write GDS
gds write outputs/chip.gds

# Extract SPICE netlist for LVS
extract all
ext2spice lvs
ext2spice
mv soc_top_flat.spice outputs/extracted.spice

puts ""
puts "============================================================"
puts "  GDS Export Complete!"
puts "  GDS file:        outputs/chip.gds"
puts "  SPICE netlist:   outputs/extracted.spice"
puts "============================================================"

quit
