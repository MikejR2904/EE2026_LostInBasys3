module clk_divider (
    input clk_in,          // Input clock (100 MHz)
    input [31:0] m,
    output reg clk_out = 0    
);
    reg [31:0] count = 0;

    always @(posedge clk_in) begin
        count <= (count == m) ? 0 : count + 1;
        clk_out <= (count == m) ? ~clk_out : clk_out;
    end
endmodule
