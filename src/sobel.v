`timescale 1ns / 1ps

module sobel(
    input wire clk,                    // Clock input
    input wire [7:0] p00, p01, p02,   // Top row pixels
    input wire [7:0] p10, p11, p12,   // Middle row pixels
    input wire [7:0] p20, p21, p22,   // Bottom row pixels
    input wire start, reset,
    output reg [7:0] magnitude,        // Output magnitude
    output reg done
);

    parameter threshold = 150;         // Edge threshold


    // Internal registers for Gx and Gy calculations
    reg signed [10:0] gx, gy;         // 11-bit signed for intermediate results
    reg [10:0] abs_gx, abs_gy;        // Absolute values
    wire [10:0] magnitude_sum;        // Sum of absolute values

    // Calculate Sobel gradients
    always @(posedge clk) begin
        // Gx = [-1 0 1; -2 0 2; -1 0 1] * window
        gx = (p02 + (p12 << 1) + p22) - (p00 + (p10 << 1) + p20);
        
        // Gy = [-1 -2 -1; 0 0 0; 1 2 1] * window
        gy = (p20 + (p21 << 1) + p22) - (p00 + (p01 << 1) + p02);
        
        // Calculate absolute values
        abs_gx = (gx < 0) ? -gx : gx;
        abs_gy = (gy < 0) ? -gy : gy;
    end

    // Approximate magnitude using Manhattan distance (|Gx| + |Gy|)
    assign magnitude_sum = abs_gx + abs_gy;

    // Scale result to fit in 8 bits (divide by 2)
    always @(posedge clk) begin
        magnitude <= (magnitude_sum > threshold) ? 8'd255 : 0;
    end

endmodule