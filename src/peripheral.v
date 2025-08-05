/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 38 and change tqvp_example to your chosen module name.
module tqvp_fir (
    input         clk,          // Clock input
    input         rst_n,        // Active-low reset

    input  [7:0]  ui_in,        // 8-bit input sample (e.g., from PMOD)
    output [7:0]  uo_out,       // 8-bit output sample (filtered)

    input  [3:0]  address,      // Memory-mapped I/O address
    input         data_write,   // Write request signal
    input  [7:0]  data_in,      // Data from processor
    output [7:0]  data_out      // Data to processor
);

    // 8-bit signed input conversion
    wire signed [7:0] x_in = ui_in;

    // Filter coefficients (example: low-pass FIR filter)
    // Coefficients: h = [3, -2, 4, 1]
    parameter signed [7:0] h0 = 8'sd3;
    parameter signed [7:0] h1 = -8'sd2;
    parameter signed [7:0] h2 = 8'sd4;
    parameter signed [7:0] h3 = 8'sd1;

    // Shift register for past inputs
    reg signed [7:0] x0, x1, x2, x3;

    // Filter output (wider to prevent overflow)
    reg signed [15:0] y_full;
    wire signed [7:0] y_out = y_full[15:8]; // Scale down or truncate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0;
            y_full <= 0;
        end else begin
            // Shift the samples
            x3 <= x2;
            x2 <= x1;
            x1 <= x0;
            x0 <= x_in;

            // Compute filter output
            y_full <= (x0 * h0) + (x1 * h1) + (x2 * h2) + (x3 * h3);
        end
    end

    // Output assignment
    assign uo_out = y_out;

    // Addressable register access (if needed)
    // Address 0: latest output
    // Address 1: latest input
    assign data_out = (address == 4'h0) ? y_out :
                      (address == 4'h1) ? x0 :
                      8'h00;

endmodule
