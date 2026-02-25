// ============================================================================
// SoC Testbench - Full System Integration Test
// ============================================================================
// Runs the demo program (count 1 to 5) and verifies GPIO outputs.
// Generates: tb/soc_tb.vcd for waveform viewing
//
// Run:
//   iverilog -o soc_tb -I rtl/core tb/soc_tb.v \
//     rtl/soc_top.v rtl/core/alu.v rtl/core/control.v \
//     rtl/core/regfile.v rtl/core/program_rom.v rtl/gpio.v
//   vvp soc_tb
//
// View waveforms:
//   gtkwave tb/soc_tb.vcd
// ============================================================================

`timescale 1ns / 1ps

module soc_tb;

    // ---- Clock and Reset ----
    reg        clk;
    reg        rst_n;
    reg  [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire       halted;

    // Clock generation: 10 MHz (100ns period) for simulation speed
    // Actual target is <= 5 MHz on silicon
    initial clk = 0;
    always #50 clk = ~clk;  // 50ns half-period = 10 MHz

    // ---- DUT Instantiation ----
    soc_top uut (
        .clk      (clk),
        .rst_n    (rst_n),
        .gpio_out (gpio_out),
        .gpio_in  (gpio_in),
        .halted   (halted)
    );

    // ---- Test tracking ----
    integer gpio_capture_count = 0;
    reg [7:0] gpio_captures [0:15];
    integer cycle_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Count clock cycles
    always @(posedge clk) begin
        if (rst_n)
            cycle_count <= cycle_count + 1;
    end

    // Capture GPIO output changes
    reg [7:0] prev_gpio_out;
    always @(posedge clk) begin
        if (rst_n) begin
            prev_gpio_out <= gpio_out;
            if (gpio_out !== prev_gpio_out && gpio_out !== 8'h00) begin
                $display("  [GPIO] Cycle %0d: gpio_out changed to 0x%02h (%0d)",
                         cycle_count, gpio_out, gpio_out);
                gpio_captures[gpio_capture_count] = gpio_out;
                gpio_capture_count = gpio_capture_count + 1;
            end
        end
    end

    // ---- Monitor CPU internals ----
    // Access internal signals for debugging
    wire [7:0]  mon_pc    = uut.u_ctrl.pc;
    wire [7:0]  mon_acc   = uut.u_ctrl.acc;
    wire [7:0]  mon_opc   = uut.u_ctrl.opcode;
    wire [1:0]  mon_state = uut.u_ctrl.state;
    wire        mon_zf    = uut.u_ctrl.zero_flag;
    wire [15:0] mon_instr = uut.u_rom.data;

    // Print execution trace
    always @(posedge clk) begin
        if (rst_n && mon_state == 2'd2) begin // EXECUTE state
            $display("  [EXEC] PC=0x%02h ACC=0x%02h OP=0x%02h ZF=%b | instr=0x%04h",
                     mon_pc, mon_acc, mon_opc, mon_zf, mon_instr);
        end
    end

    // ---- Task: Check expected value ----
    task check_gpio;
        input integer index;
        input [7:0] expected;
        begin
            if (index < gpio_capture_count) begin
                if (gpio_captures[index] === expected) begin
                    $display("  [PASS] GPIO capture %0d = 0x%02h (expected 0x%02h)",
                             index, gpio_captures[index], expected);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [FAIL] GPIO capture %0d = 0x%02h (expected 0x%02h)",
                             index, gpio_captures[index], expected);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("  [FAIL] GPIO capture %0d not recorded (expected 0x%02h)",
                         index, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ---- Main test sequence ----
    initial begin
        $dumpfile("tb/soc_tb.vcd");
        $dumpvars(0, soc_tb);

        $display("");
        $display("============================================================");
        $display("  SoC Integration Testbench");
        $display("  Program: Count 1 to 5, output each value, then halt");
        $display("============================================================");
        $display("");

        // Initialize
        rst_n   = 0;
        gpio_in = 8'h00;
        prev_gpio_out = 8'h00;

        // Hold reset for 5 clock cycles
        repeat(5) @(posedge clk);
        #10;
        rst_n = 1;
        $display("  [INFO] Reset released at time %0t", $time);
        $display("");

        // Wait for halt or timeout
        begin : wait_for_halt
            integer timeout;
            timeout = 0;
            while (!halted && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (halted) begin
                $display("");
                $display("  [INFO] CPU halted at cycle %0d, time %0t", cycle_count, $time);
            end else begin
                $display("");
                $display("  [FAIL] TIMEOUT: CPU did not halt within 1000 cycles!");
                fail_count = fail_count + 1;
            end
        end

        // Wait a few more cycles for signal settling
        repeat(5) @(posedge clk);

        // ---- Verify GPIO outputs ----
        $display("");
        $display("------------------------------------------------------------");
        $display("  Verifying GPIO Output Sequence");
        $display("------------------------------------------------------------");

        // The demo program should output: 1, 2, 3, 4, 5
        check_gpio(0, 8'h01);
        check_gpio(1, 8'h02);
        check_gpio(2, 8'h03);
        check_gpio(3, 8'h04);
        check_gpio(4, 8'h05);

        // ---- Verify halt status ----
        if (halted) begin
            $display("  [PASS] CPU is in HALT state");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] CPU is NOT in HALT state");
            fail_count = fail_count + 1;
        end

        // ---- Summary ----
        $display("");
        $display("============================================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("  Total GPIO outputs captured: %0d", gpio_capture_count);
        $display("  Total cycles executed: %0d", cycle_count);
        $display("============================================================");

        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED - READY FOR SYNTHESIS <<<");
        else
            $display("  >>> SOME TESTS FAILED - FIX BEFORE SYNTHESIS <<<");

        $display("");
        #100;
        $finish;
    end

endmodule
