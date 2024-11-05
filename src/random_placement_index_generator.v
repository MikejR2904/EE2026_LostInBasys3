module random_placement_index_generator#(parameter SIZE = 256, LFSR_BITS = 8)(
    input clk,
    input reset,
    input en,
    output reg [7:0] random_index
);
    reg [LFSR_BITS-1:0] lfsr = 8'hA5; // Initialize with a non-zero seed
    wire feedback;

    assign feedback = lfsr[LFSR_BITS-1] ^ lfsr[LFSR_BITS-2] ^ lfsr[LFSR_BITS-4] ^ lfsr[3];

    always @(posedge clk) begin
        if (en) begin
            lfsr <= {lfsr[LFSR_BITS-2:0], feedback};
            random_index <= lfsr % SIZE;
        end
    end

endmodule
