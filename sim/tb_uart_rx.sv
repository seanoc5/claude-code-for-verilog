// tb_uart_rx.sv — self-checking testbench for uart_rx.
//
// Drives the rx line at the configured bit rate, sends a handful of bytes,
// and asserts that the receiver delivers each byte correctly. Exits non-zero
// (via $fatal) if any check fails.

`timescale 1ns/1ps

module tb_uart_rx;
    localparam int  CLKS_PER_BIT = 8;
    localparam time CLK_PERIOD   = 10ns;

    logic       clk = 1'b0;
    logic       rst_n = 1'b0;
    logic       rx = 1'b1;       // line idles high
    logic [7:0] data;
    logic       valid;
    logic       frame_err;

    int unsigned errors = 0;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (.*);

    // Free-running clock
    always #(CLK_PERIOD/2) clk <= ~clk;

    // Drive one UART frame onto rx (start, 8 data LSB-first, stop)
    task automatic send_byte(input logic [7:0] b);
        rx = 1'b0;
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            rx = b[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        rx = 1'b1;
        repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    // Wait for `valid` and check the received byte
    task automatic expect_byte(input logic [7:0] b, input string label);
        int timeout = 12 * CLKS_PER_BIT;
        while (!valid && timeout > 0) begin
            @(posedge clk);
            timeout--;
        end
        if (!valid) begin
            $display("FAIL [%s]: no valid pulse seen", label);
            errors++;
        end else if (data !== b) begin
            $display("FAIL [%s]: expected 0x%02h, got 0x%02h", label, b, data);
            errors++;
        end else if (frame_err) begin
            $display("FAIL [%s]: unexpected frame_err", label);
            errors++;
        end else begin
            $display("PASS [%s]: 0x%02h", label, b);
        end
    endtask

    initial begin
        // Reset
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        fork send_byte(8'h55); expect_byte(8'h55, "alternating 0x55"); join
        fork send_byte(8'hA5); expect_byte(8'hA5, "0xA5");             join
        fork send_byte(8'h00); expect_byte(8'h00, "all zeros");        join
        fork send_byte(8'hFF); expect_byte(8'hFF, "all ones");         join
        fork send_byte(8'h42); expect_byte(8'h42, "ascii 'B'");        join

        if (errors == 0) begin
            $display("\n=== ALL TESTS PASSED ===");
            $finish;
        end else begin
            $fatal(1, "\n=== %0d TEST(S) FAILED ===", errors);
        end
    end

    // Safety net so a broken DUT can't hang CI
    initial begin
        #1ms;
        $fatal(1, "simulation timeout");
    end
endmodule
