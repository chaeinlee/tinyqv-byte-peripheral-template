
/*
 * Copyright (c) 2025 vibhee
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 38 and change tqvp_example to your chosen module name.
module tqvp_fir_filter (
    input         clk,          // System clock, e.g., 64 MHz from TinyQV core
    input         rst_n,        // Active-low reset (synchronous reset)

    input  [7:0]  ui_in,        // Unused input PMOD (can be used for external sample input if needed)
    output [7:0]  uo_out,       // Unused output PMOD (can be used for debug or output)

    input  [3:0]  address,      // 4-bit memory-mapped address from processor
    input         data_write,   // Write strobe from processor (high when writing)
    input  [7:0]  data_in,      // 8-bit data from processor (valid during write)

    output [7:0]  data_out      // 8-bit data to processor (depends on address)
);

    // === FIR Filter Parameters ===
    parameter TAPS = 4; // Number of filter taps (number of coefficients and samples used)

    // === Coefficient Definitions ===
    // FIR filter coefficients — fixed and symmetric for low-pass response
    // You can change these as needed for different filtering characteristics
    wire signed [15:0] coeffs[0:TAPS-1];
    assign coeffs[0] = 16'sd5;
    assign coeffs[1] = 16'sd10;
    assign coeffs[2] = 16'sd10;
    assign coeffs[3] = 16'sd5;

    // === Internal Registers ===
    // Sample shift register to hold the last TAPS number of input samples
    reg signed [15:0] samples[0:TAPS-1];

    // Output register to store final filtered value
    reg signed [15:0] out_data_reg;

    // Flag to indicate a new valid filtered output is available
    reg               out_valid;

    // Temporary integer for looping
    integer i;

    // === FIR Filter Computation Block ===
    // Triggered only when a new input sample is written to address 0
    always @(posedge clk) begin
        if (!rst_n) begin
            // On reset: clear all sample values and output
            for (i = 0; i < TAPS; i = i + 1)
                samples[i] <= 16'sd0;

            out_data_reg <= 16'sd0;
            out_valid <= 1'b0;

        end else begin
            // Default: clear valid flag unless new computation occurs
            out_valid <= 1'b0;

            // When processor writes a new sample at address 0
            if (data_write && address == 4'h0) begin
                // Shift the sample history to make room for new sample
                for (i = TAPS-1; i > 0; i = i - 1)
                    samples[i] <= samples[i-1];

                // Insert new sample at the beginning (zero-extend 8-bit input to 16-bit signed)
                samples[0] <= {8'd0, data_in};

                // Perform Multiply-Accumulate (MAC) for FIR filtering
                out_data_reg <= samples[0]*coeffs[0] +
                                samples[1]*coeffs[1] +
                                samples[2]*coeffs[2] +
                                samples[3]*coeffs[3];

                // Indicate that output is now valid
                out_valid <= 1'b1;
            end
        end
    end

    // === Output PMOD Signals ===
    // Currently not used; set to zero or use for debugging output
    assign uo_out = 8'd0;

    // === Memory-Mapped Data Read Logic ===
    // Responds to processor reads at various addresses:
    //   address 0x1: upper byte of output
    //   address 0x2: lower byte of output
    //   address 0x3: output valid flag (bit 0 = 1 if new data is available)
    assign data_out = (address == 4'h1) ? out_data_reg[15:8] :  // MSB of output
                      (address == 4'h2) ? out_data_reg[7:0]  :  // LSB of output
                      (address == 4'h3) ? {7'd0, out_valid}   : // Valid flag in bit 0
                      8'd0; // Default to zero for unassigned addresses

endmodule
