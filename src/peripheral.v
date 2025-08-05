/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 38 and change tqvp_example to your chosen module name.
module tqvp_vibhee_fir_filter (
    input clk,                 // Clock signal
    input rst,                 // Reset signal (synchronous, active high)
    input [7:0] in_data,       // 8-bit input data
    input in_valid,           // Input valid signal (indicates new data)
    output reg [15:0] out_data, // 16-bit filtered output data
    output reg out_valid       // Output valid signal (indicates out_data is valid)
);
    parameter TAPS = 4;  // Number of FIR filter taps (coefficients/samples)

    // Declare filter coefficients (signed 16-bit) and sample buffer
    reg signed [15:0] coeffs [0:TAPS-1];  // Coefficient array
    reg signed [15:0] samples[0:TAPS-1]; // Shift register for past input samples

    integer i;

    // Initialize filter coefficients (e.g., symmetric FIR low-pass)
    initial begin
        coeffs[0] = 16'sd5;
        coeffs[1] = 16'sd10;
        coeffs[2] = 16'sd10;
        coeffs[3] = 16'sd5;
    end

    // Main logic block (executed on rising edge of clock)
    always @(posedge clk) begin
        if (rst) begin
            // On reset, clear all sample registers and output signals
            for (i = 0; i < TAPS; i = i + 1)
                samples[i] <= 16'sd0;

            out_data <= 16'sd0;
            out_valid <= 0;

        end else if (in_valid) begin
            // If input is valid, shift the sample buffer to make room for new sample
            for (i = TAPS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];

            // Insert new input sample (zero-extended to 16 bits) at the front
            samples[0] <= {8'd0, in_data};

            // Multiply-accumulate (MAC) operation for FIR filtering
            out_data <= samples[0]*coeffs[0] + samples[1]*coeffs[1]
                      + samples[2]*coeffs[2] + samples[3]*coeffs[3];

            // Set output valid signal
            out_valid <= 1;

        end else begin
            // If input is not valid, output is not valid
            out_valid <= 0;
        end
    end
endmodule
