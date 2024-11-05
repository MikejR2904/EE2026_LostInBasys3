module collectibles_random_placement #(parameter MIN_DISTANCE = 3)(
    input clk,
    input reset,
    input en,
    input [3:0] x_seeker_init,
    input [3:0] y_seeker_init,
    input [3:0] x_hider_init,
    input [3:0] y_hider_init,
    input [7:0] random_index,
    input [1:0] random_collectible_type,
    input [8:0] bram_mem_in,
    output reg [8:0] bram_mem_out,
    output reg [7:0] found_index,
    output reg finished_placement = 0,
    output reg [15:0] led,
    output reg we_collectible,
    output reg [7:0] bram_addr_out
);
    // Collectibles Placement Logic
    reg [3:0] placed_items = 0;
    reg [1:0] wait_counter;

    // State Machine
    reg [2:0] current_state, next_state;
    localparam IDLE = 3'b000;
    localparam GENERATE_INDEX = 3'b001;
    localparam READ_MEMORY = 3'b010;
    localparam CHECK_POSITION = 3'b011;
    localparam FOUND_EMPTY = 3'b100;
    localparam DONE = 3'b101;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            finished_placement <= 0;
            we_collectible <= 0;
            bram_addr_out <= 0;
            wait_counter <= 0;
            placed_items <= 0;
        end else if (en) begin
            current_state <= next_state;
            if (current_state == DONE) begin
                finished_placement <= 1;
            end
            if (current_state == GENERATE_INDEX) begin
                bram_addr_out <= random_index;
                wait_counter <= 0;
            end else if (current_state == READ_MEMORY) begin
                wait_counter <= wait_counter + 1;
            end else if (current_state == FOUND_EMPTY) begin
                found_index <= random_index;
                bram_mem_out <= {5'b0, random_collectible_type, bram_mem_in[0]}; // Preserve wall bit
                we_collectible <= 1;
                placed_items <= placed_items + 1;
            end else begin
                we_collectible <= 0;
            end
        end else begin
            we_collectible <= 0; // Ensure it's 0 when not enabled
        end
    end

    // State transitions
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (placed_items < 10) begin
                    next_state = GENERATE_INDEX;
                end else begin
                    next_state = DONE;
                end
            end
            GENERATE_INDEX: begin
                next_state = READ_MEMORY;
            end
            READ_MEMORY: begin
                if (wait_counter == 1) begin
                    next_state = CHECK_POSITION;
                end else begin
                    next_state = READ_MEMORY;
                end
            end
            CHECK_POSITION: begin
                if (bram_mem_in[0] == 0 && bram_mem_in[3:1] == 3'b000 && is_valid_position(get_x(random_index), get_y(random_index))) begin
                    next_state = FOUND_EMPTY;
                end else begin
                    next_state = GENERATE_INDEX;
                end
            end
            FOUND_EMPTY: begin
                next_state = IDLE;
            end
            DONE: begin
                next_state = DONE;
            end
            default: next_state = IDLE;
        endcase
    end

    function [3:0] get_x;
        input [7:0] idx;
        get_x = idx % 16;
    endfunction

    function [3:0] get_y;
        input [7:0] idx;
        get_y = idx / 16;
    endfunction

    function is_valid_position;
        input [3:0] x_pos, y_pos;
        reg [15:0] dist_seeker, dist_hider;
        begin
            dist_seeker = abs_diff(x_pos, x_seeker_init) + abs_diff(y_pos, y_seeker_init);
            dist_hider = abs_diff(x_pos, x_hider_init) + abs_diff(y_pos, y_hider_init);
            is_valid_position = (dist_seeker >= MIN_DISTANCE) && (dist_hider >= MIN_DISTANCE);
        end
    endfunction

    function [15:0] abs_diff;
        input [15:0] a, b;
        abs_diff = (a > b) ? (a - b) : (b - a);
    endfunction

endmodule
