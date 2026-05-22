`timescale 1ns/1ps

// uart_rx.sv — 8-N-1 UART receiver.
//
// 8 data bits, no parity, 1 stop bit. LSB first.
// CLKS_PER_BIT sets the bit period in clock cycles. For real silicon you'd
// pick e.g. round(clk_hz / baud_hz). For simulation we use a small value so
// tests run fast.

module uart_rx #(
    parameter int CLKS_PER_BIT = 8
) (
    input  logic       clk,
    input  logic       rst_n,      // active-low reset
    input  logic       rx,         // serial input (idle high)
    output logic [7:0] data,       // received byte (valid while `valid` is high)
    output logic       valid,      // 1-cycle pulse when a byte is ready
    output logic       frame_err   // high with `valid` if stop bit was low
);

    typedef enum logic [2:0] {
        IDLE, START, DATA, STOP, CLEANUP
    } state_t;

    localparam int CNT_W = $clog2(CLKS_PER_BIT);
    localparam logic [CNT_W-1:0] BIT_MAX  = CNT_W'(CLKS_PER_BIT - 1);
    localparam logic [CNT_W-1:0] HALF_BIT = CNT_W'((CLKS_PER_BIT - 1) / 2);

    state_t                state;
    logic [CNT_W-1:0]      clk_cnt;
    logic [2:0]            bit_idx;
    logic [7:0]            data_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_cnt   <= '0;
            bit_idx   <= '0;
            data_r    <= '0;
            data      <= '0;
            valid     <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            valid <= 1'b0;  // default: only pulses for one cycle
            case (state)
                IDLE: begin
                    clk_cnt   <= '0;
                    bit_idx   <= '0;
                    frame_err <= 1'b0;
                    if (rx == 1'b0) state <= START;  // start bit edge
                end

                START: begin
                    // Sample at the middle of the start bit to confirm it's real
                    if (clk_cnt == HALF_BIT) begin
                        if (rx == 1'b0) begin
                            clk_cnt <= '0;
                            state   <= DATA;
                        end else begin
                            state <= IDLE;  // glitch, not a real start
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_cnt < BIT_MAX) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt         <= '0;
                        data_r[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= '0;
                            state   <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (clk_cnt < BIT_MAX) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        data      <= data_r;
                        valid     <= 1'b1;
                        frame_err <= (rx == 1'b0);  // stop bit should be high
                        clk_cnt   <= '0;
                        state     <= CLEANUP;
                    end
                end

                CLEANUP: state <= IDLE;
                default:  state <= IDLE;
            endcase
        end
    end
endmodule
