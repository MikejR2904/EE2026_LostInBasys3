module rising_edge_detector(
    input wire clk,
    input wire signal_in,
    output reg signal_out
);

    reg prev_state = 0;

    always @(posedge clk) begin
        signal_out <= (signal_in && !prev_state);
        prev_state <= signal_in;
    end
endmodule
