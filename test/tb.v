`timescale 1ns / 1ps

module tb;

    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

`ifdef GL_TEST
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
`endif

    tt_um_fidel_makatia_digital_tapeout uut (
`ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
`endif
        .clk    (clk),
        .rst_n  (rst_n),
        .ena    (ena),
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe)
    );

    // Clock generation: 10 MHz (100ns period)
    initial clk = 0;
    always #50 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer gpio_capture_count;
    reg [7:0] gpio_captures [0:15];
    reg [7:0] prev_uo_out;

    // Capture output changes
    always @(posedge clk) begin
        if (rst_n && ena) begin
            if (uo_out !== prev_uo_out && uo_out !== 8'h00) begin
                $display("  [GPIO] uo_out changed to 0x%02h (%0d)", uo_out, uo_out);
                gpio_captures[gpio_capture_count] = uo_out;
                gpio_capture_count = gpio_capture_count + 1;
            end
            prev_uo_out <= uo_out;
        end
    end

    // Check helper task
    task check_gpio;
        input integer index;
        input [7:0] expected;
        begin
            if (index < gpio_capture_count) begin
                if (gpio_captures[index] === expected) begin
                    $display("  [PASS] GPIO capture %0d = %0d", index, gpio_captures[index]);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [FAIL] GPIO capture %0d = %0d (expected %0d)",
                             index, gpio_captures[index], expected);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("  [FAIL] GPIO capture %0d not recorded (only %0d captures)",
                         index, gpio_capture_count);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Main test
    initial begin
        $display("============================================================");
        $display("  TinyTapeout SoC Testbench - Count 1 to 5");
        $display("============================================================");

        // Initialize
        pass_count = 0;
        fail_count = 0;
        gpio_capture_count = 0;
        rst_n = 0;
        ena   = 0;
        ui_in = 8'h00;
        uio_in = 8'h00;
        prev_uo_out = 8'h00;

        // Hold reset for 5 cycles
        repeat(5) @(posedge clk);
        rst_n = 1;
        ena   = 1;
        $display("  [INFO] Reset released, design enabled");

        // Wait for halted signal or timeout
        begin : wait_halt
            integer timeout;
            timeout = 0;
            while (!uio_out[0] && timeout < 2000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (uio_out[0])
                $display("  [INFO] CPU halted after %0d cycles", timeout);
            else begin
                $display("  [FAIL] TIMEOUT after %0d cycles", timeout);
                fail_count = fail_count + 1;
            end
        end

        // Allow a few more cycles for final output to settle
        repeat(5) @(posedge clk);

        // Verify GPIO output sequence: 1, 2, 3, 4, 5
        $display("");
        $display("  Checking GPIO output sequence...");
        check_gpio(0, 8'h01);
        check_gpio(1, 8'h02);
        check_gpio(2, 8'h03);
        check_gpio(3, 8'h04);
        check_gpio(4, 8'h05);

        // Verify halted signal
        $display("");
        $display("  Checking control signals...");
        if (uio_out[0]) begin
            $display("  [PASS] Halted signal asserted on uio_out[0]");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Halted signal not asserted");
            fail_count = fail_count + 1;
        end

        // Verify uio_oe configuration
        if (uio_oe === 8'h01) begin
            $display("  [PASS] uio_oe = 0x01 (correct)");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] uio_oe = 0x%02h (expected 0x01)", uio_oe);
            fail_count = fail_count + 1;
        end

        // Summary
        $display("");
        $display("============================================================");
        if (fail_count == 0)
            $display("  ALL %0d TESTS PASSED", pass_count);
        else
            $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("============================================================");

        #100;
        $finish;
    end

endmodule
