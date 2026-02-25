// ============================================================================
// ALU Testbench - Unit test for the ALU module
// ============================================================================
// Tests all ALU operations and verifies results.
// Generates: tb/alu_tb.vcd for waveform viewing
// Run: iverilog -o alu_tb tb/alu_tb.v rtl/core/alu.v && vvp alu_tb
// ============================================================================

`timescale 1ns / 1ps

module alu_tb;

    reg  [7:0] a, b;
    reg  [3:0] alu_op;
    wire [7:0] result;
    wire       zero_flag;
    wire       carry_flag;

    // Instantiate ALU
    alu uut (
        .a          (a),
        .b          (b),
        .alu_op     (alu_op),
        .result     (result),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check;
        input [7:0] expected_result;
        input       expected_zero;
        input       expected_carry;
        input [63:0] test_name; // 8-char name
        begin
            test_num = test_num + 1;
            #1; // Let combinational logic settle
            if (result === expected_result && zero_flag === expected_zero && carry_flag === expected_carry) begin
                $display("  [PASS] Test %0d: op=%h a=%h b=%h -> result=%h z=%b c=%b",
                         test_num, alu_op, a, b, result, zero_flag, carry_flag);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] Test %0d: op=%h a=%h b=%h -> result=%h (exp %h) z=%b (exp %b) c=%b (exp %b)",
                         test_num, alu_op, a, b, result, expected_result,
                         zero_flag, expected_zero, carry_flag, expected_carry);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb/alu_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("");
        $display("============================================");
        $display("  ALU Testbench - Unit Tests");
        $display("============================================");

        // ---- Test NOP (pass-through) ----
        $display("\n--- NOP / Pass-through ---");
        a = 8'h42; b = 8'h00; alu_op = 4'h0;
        check(8'h42, 1'b0, 1'b0, "NOP     ");

        a = 8'h00; b = 8'hFF; alu_op = 4'h0;
        check(8'h00, 1'b1, 1'b0, "NOP_ZERO");

        // ---- Test ADD ----
        $display("\n--- ADD ---");
        a = 8'h10; b = 8'h20; alu_op = 4'h1;
        check(8'h30, 1'b0, 1'b0, "ADD_OK  ");

        a = 8'hFF; b = 8'h01; alu_op = 4'h1;
        check(8'h00, 1'b1, 1'b1, "ADD_OVF ");

        a = 8'h80; b = 8'h80; alu_op = 4'h1;
        check(8'h00, 1'b1, 1'b1, "ADD_OVF2");

        // ---- Test SUB ----
        $display("\n--- SUB ---");
        a = 8'h30; b = 8'h10; alu_op = 4'h2;
        check(8'h20, 1'b0, 1'b0, "SUB_OK  ");

        a = 8'h05; b = 8'h05; alu_op = 4'h2;
        check(8'h00, 1'b1, 1'b0, "SUB_ZERO");

        a = 8'h00; b = 8'h01; alu_op = 4'h2;
        check(8'hFF, 1'b0, 1'b1, "SUB_UNF ");

        // ---- Test AND ----
        $display("\n--- AND ---");
        a = 8'hF0; b = 8'h0F; alu_op = 4'h3;
        check(8'h00, 1'b1, 1'b0, "AND_ZERO");

        a = 8'hFF; b = 8'hAA; alu_op = 4'h3;
        check(8'hAA, 1'b0, 1'b0, "AND_MASK");

        // ---- Test OR ----
        $display("\n--- OR ---");
        a = 8'hF0; b = 8'h0F; alu_op = 4'h4;
        check(8'hFF, 1'b0, 1'b0, "OR_FULL ");

        a = 8'h00; b = 8'h00; alu_op = 4'h4;
        check(8'h00, 1'b1, 1'b0, "OR_ZERO ");

        // ---- Test XOR ----
        $display("\n--- XOR ---");
        a = 8'hFF; b = 8'hFF; alu_op = 4'h5;
        check(8'h00, 1'b1, 1'b0, "XOR_ZERO");

        a = 8'hAA; b = 8'h55; alu_op = 4'h5;
        check(8'hFF, 1'b0, 1'b0, "XOR_FULL");

        // ---- Test NOT ----
        $display("\n--- NOT ---");
        a = 8'h00; b = 8'h00; alu_op = 4'h6;
        check(8'hFF, 1'b0, 1'b0, "NOT_FULL");

        a = 8'hFF; b = 8'h00; alu_op = 4'h6;
        check(8'h00, 1'b1, 1'b0, "NOT_ZERO");

        // ---- Test SHL ----
        $display("\n--- SHL ---");
        a = 8'h01; b = 8'h00; alu_op = 4'h7;
        check(8'h02, 1'b0, 1'b0, "SHL_1   ");

        a = 8'h80; b = 8'h00; alu_op = 4'h7;
        check(8'h00, 1'b1, 1'b1, "SHL_OVF ");

        // ---- Test SHR ----
        $display("\n--- SHR ---");
        a = 8'h02; b = 8'h00; alu_op = 4'h8;
        check(8'h01, 1'b0, 1'b0, "SHR_1   ");

        a = 8'h01; b = 8'h00; alu_op = 4'h8;
        check(8'h00, 1'b1, 1'b1, "SHR_OUT ");

        // ---- Test INC ----
        $display("\n--- INC ---");
        a = 8'h05; b = 8'h00; alu_op = 4'h9;
        check(8'h06, 1'b0, 1'b0, "INC_OK  ");

        a = 8'hFF; b = 8'h00; alu_op = 4'h9;
        check(8'h00, 1'b1, 1'b1, "INC_OVF ");

        // ---- Test DEC ----
        $display("\n--- DEC ---");
        a = 8'h05; b = 8'h00; alu_op = 4'hA;
        check(8'h04, 1'b0, 1'b0, "DEC_OK  ");

        a = 8'h00; b = 8'h00; alu_op = 4'hA;
        check(8'hFF, 1'b0, 1'b1, "DEC_UNF ");

        // ---- Summary ----
        $display("\n============================================");
        $display("  Results: %0d PASSED, %0d FAILED out of %0d",
                 pass_count, fail_count, test_num);
        $display("============================================");

        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED <<<\n");
        else
            $display("  >>> SOME TESTS FAILED <<<\n");

        #10;
        $finish;
    end

endmodule
