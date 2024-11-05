module debounce(
    input wire clk,        // System clock
    input wire btn_in,     // Raw button input
    output reg btn_out     // Debounced button output
);

    reg [15:0] counter = 0;
    reg stable_state = 0;
    reg btn_sync = 0;

    always @(posedge clk) begin
        btn_sync <= btn_in;
        if (btn_sync == stable_state) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 16'hFFFF) begin
                stable_state <= btn_sync;
                counter <= 0;
            end
        end
    end

    always @(posedge clk) begin
        btn_out <= stable_state;
    end
endmodule
