module random_collectible_type_generator(
    input clk,
    input reset,
    input en,
    output reg [1:0] random_type
);
    reg [3:0] lfsr = 4'hF; // Initialize with a non-zero seed
    wire feedback;

    assign feedback = lfsr[3] ^ lfsr[2];

    always @(posedge clk) begin
        if (reset) begin
            lfsr <= 4'hF;
            random_type <= 2'b00;
        end else if (en) begin
            lfsr <= {lfsr[2:0], feedback};
            random_type <= (lfsr[1:0] % 3) + 1; // Random type 1 to 3
        end
    end
endmodule
