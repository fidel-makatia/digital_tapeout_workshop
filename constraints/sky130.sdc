# ============================================================================
# SKY130 Timing Constraints (SDC)
# ============================================================================
# Target: <= 5 MHz clock (200ns period)
# This is intentionally conservative for guaranteed tapeout success.
# ============================================================================

# Clock definition
create_clock -name clk -period 200.0 [get_ports clk]

# Input delay (generous)
set_input_delay -clock clk 10.0 [all_inputs]

# Output delay (generous)
set_output_delay -clock clk 10.0 [all_outputs]

# Drive strength and load
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [all_inputs]
set_load 0.05 [all_outputs]
