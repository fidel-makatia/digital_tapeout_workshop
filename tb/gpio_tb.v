// ============================================================================
// GPIO Testbench - Unit test for GPIO module
// ============================================================================
// Tests output latching and input pass-through.
// Generates: tb/gpio_tb.vcd
// Run: iverilog -o gpio_tb tb/gpio_tb.v rtl/gpio.v && vvp gpio_tb
// ============================================================================

`timescale 1ns / 1ps

module gpio_tb;

    reg        clk;
    reg        rst_n;
    reg  [7:0] data_in;
    reg        write_en;
    wire [7:0] data_out;
    wire [7:0] gpio_pins_out;
    reg  [7:0] gpio_pins_in;

    initial clk = 0;
    always #50 clk = ~clk;

    gpio uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_in       (data_in),
        .write_en      (write_en),
        .data_out      (data_out),
        .gpio_pins_out (gpio_pins_out),
        .gpio_pins_in  (gpio_pins_in)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    task check_out;
        input [7:0] expected;
        input [63:0] name;
        begin
            @(posedge clk); #1;
            if (gpio_pins_out === expected) begin
                $display("  [PASS] %s: gpio_pins_out = 0x%02h", name, gpio_pins_out);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s: gpio_pins_out = 0x%02h (exp 0x%02h)",
                         name, gpio_pins_out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb/gpio_tb.vcd");
        $dumpvars(0, gpio_tb);

        $display("");
        $display("============================================");
        $display("  GPIO Testbench");
        $display("============================================");

        rst_n = 0; data_in = 8'h00; write_en = 0; gpio_pins_in = 8'h00;
        repeat(3) @(posedge clk);

        // Test 1: Reset state
        #1;
        if (gpio_pins_out === 8'h00) begin
            $display("  [PASS] Reset: output = 0x00"); pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Reset: output = 0x%02h", gpio_pins_out); fail_count = fail_count + 1;
        end

        rst_n = 1;
        @(posedge clk);

        // Test 2: Write 0xAA
        data_in = 8'hAA; write_en = 1;
        check_out(8'hAA, "Write AA");
        write_en = 0;

        // Test 3: Output holds without write_en
        data_in = 8'hBB;
        check_out(8'hAA, "Hold AA ");

        // Test 4: Write 0x55
        data_in = 8'h55; write_en = 1;
        check_out(8'h55, "Write 55");
        write_en = 0;

        // Test 5: Input pass-through
        gpio_pins_in = 8'hDE;
        @(posedge clk); #1;
        if (data_out === 8'hDE) begin
            $display("  [PASS] Input: data_out = 0x%02h", data_out); pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Input: data_out = 0x%02h (exp 0xDE)", data_out); fail_count = fail_count + 1;
        end

        $display("\n============================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("============================================\n");

        #100;
        $finish;
    end

endmodule
