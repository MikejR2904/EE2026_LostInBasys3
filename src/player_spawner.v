module player_spawner(
    input clk,
    input reset,
    input en,
    input [8:0] bram_dout, // BRAM data output
    input [7:0] random_index,
    output reg [7:0] bram_addr,
    output reg [3:0] player_x,
    output reg [3:0] player_y,
    output reg player_placement_done
);
    // State machine
    reg [1:0] state;
    parameter PP_IDLE = 2'b00, PP_READ = 2'b01, PP_CHECK = 2'b10;
    reg bram_wait;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= PP_IDLE;
            player_placement_done <= 0;
            bram_wait <= 0;
        end else if (en) begin
            case (state)
                PP_IDLE: begin
                    bram_addr <= random_index;
                    bram_wait <= 0;
                    state <= PP_READ;
                end
                PP_READ: begin
                    if (bram_wait) begin
                        state <= PP_CHECK;
                    end else begin
                        bram_wait <= 1; // Wait for BRAM read latency
                    end
                end
                PP_CHECK: begin
                    if (bram_dout[0] == 0) begin // Path
                        player_x <= bram_addr % 16;
                        player_y <= bram_addr / 16;
                        player_placement_done <= 1;
                        state <= PP_IDLE;
                    end else begin
                        // Try another index
                        bram_addr <= random_index;
                        bram_wait <= 0;
                        state <= PP_READ;
                    end
                end
                default: state <= PP_IDLE;
            endcase
        end else begin
            state <= PP_IDLE;
            player_placement_done <= 0;
            bram_wait <= 0;
        end
    end
endmodule
