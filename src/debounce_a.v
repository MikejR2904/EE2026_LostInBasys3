module debounce_a (
    input clk,               // System clock
    input btn_in,            // Raw button input
    output reg btn_out       // Debounced button output
);
    // Parameters
    parameter CLK_FREQ = 100_000_000;       // System clock frequency in Hz
    parameter DEBOUNCE_TIME_MS = 10;        // Debounce time in milliseconds
    localparam integer DEBOUNCE_COUNT = (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;

    // Internal registers
    reg [31:0] counter = 0;    // Counter to measure the debounce interval
    reg btn_sync_0;            // First stage synchronizer for input
    reg btn_sync_1;            // Second stage synchronizer for input
    reg btn_stable = 0;        // Stable button value after debouncing

    // Synchronize the asynchronous button input to the clock domain
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // Debouncing logic
    always @(posedge clk) begin
        if (btn_sync_1 != btn_stable) begin
            if (counter < DEBOUNCE_COUNT) begin
                counter <= counter + 1;
            end else begin
                btn_stable <= btn_sync_1;   // Update stable button value
                counter <= 0;
            end
        end else begin
            counter <= 0;
        end
    end

    // Assign the stable debounced button output
    always @(posedge clk) begin
        btn_out <= btn_stable;
    end

endmodule
