`timescale 1ns / 1ps

module median9 (
    input [7:0] w0, w1, w2, w3, w4, w5, w6, w7, w8,
    output reg [7:0] median
);

    reg [7:0] sorted [0:8];
    reg [9:0] i, j;

    always @* begin
        // Initialize array
        sorted[0] = w0;
        sorted[1] = w1;
        sorted[2] = w2;
        sorted[3] = w3;
        sorted[4] = w4;
        sorted[5] = w5;
        sorted[6] = w6;
        sorted[7] = w7;
        sorted[8] = w8;

        // Bubble sort
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (sorted[j] > sorted[j+1]) begin
                    // Swap values
                    sorted[j] = sorted[j] ^ sorted[j+1];
                    sorted[j+1] = sorted[j] ^ sorted[j+1];
                    sorted[j] = sorted[j] ^ sorted[j+1];
                end
            end
        end

        // Assign median (middle value)
        median = sorted[4];
    end

endmodule