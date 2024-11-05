module maze_bram (
    input wire clk_a,
    input wire en_a,
    input wire we_a,
    input wire [7:0] addr_a,
    input wire [8:0] din_a,
    output reg [8:0] dout_a,
    input wire clk_b,
    input wire en_b,
    input wire we_b,
    input wire [7:0] addr_b,
    input wire [8:0] din_b,
    output reg [8:0] dout_b
);
    // Define memory
    (* ram_style = "block" *) reg [8:0] memory [0:255]; // Force BRAM usage

    always @(posedge clk_a) begin
        if (en_a) begin
            if (we_a) begin
                memory[addr_a] <= din_a;
            end
            dout_a <= memory[addr_a];
        end
    end

    always @(posedge clk_b) begin
        if (en_b) begin
            if (we_b) begin
                memory[addr_b] <= din_b;
            end
            dout_b <= memory[addr_b];
        end
    end
endmodule
