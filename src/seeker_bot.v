module seeker_bot(
    input wire clk,
    input wire rst,
    input wire [7:0] hider_x,      // Hider's x position
    input wire [7:0] hider_y,      // Hider's y position
    input [2:0] level_select,   
    output reg [7:0] seeker_x,     // Seeker's current x position
    output reg [7:0] seeker_y,     // Seeker's current y position
    output reg [1:0] dir,
    output reg done = 0,
    output reg winner
);

// Maze data is now a wire
 wire [255:0] maze_data;

 // Function to get maze data based on level
 function [255:0] get_maze_data;
     input [2:0] level;
     begin
         case (level)
             0: get_maze_data = {256{1'b1}};
             1 : get_maze_data = {
                16'b1111111111111111,
                16'b1000001000000001,
                16'b1011101011011101,
                16'b1010000001000101,
                16'b1011111101010101,
                16'b1010001001010101,
                16'b1010101011110101,
                16'b1000101000110101,
                16'b1010001010000101,
                16'b1010111011111101,
                16'b1010101000010101,
                16'b1010101011110101,
                16'b1010100000010101,
                16'b1010111101010001,
                16'b1010000001000101,
                16'b1111111111111111
            };
            
            2: 
            get_maze_data = {
                16'b1111111111111111,
                16'b1000000000000001,
                16'b1111111011110101,
                16'b1000001001000101,
                16'b1011101111011101,
                16'b1010000000010001,
                16'b1011111111110111,
                16'b1000001000010101,
                16'b1010100001000001,
                16'b1010111011111101,
                16'b1000101000000101,
                16'b1110101011110111,
                16'b1010001000010001,
                16'b1011101011011101,
                16'b1000001000000101,
                16'b1111111111111111
            };
            
            
            3: 
            get_maze_data = {
                16'b1111111111111111,
                16'b1000001000000001,
                16'b1011111011111101,
                16'b1000100000010001,
                16'b1110101111010111,
                16'b1000101000010001,
                16'b1010101011111101,
                16'b1010101000010101,
                16'b1010000001000101,
                16'b1011111101011101,
                16'b1010000001010001,
                16'b1011111101010111,
                16'b1000100000010101,
                16'b1010101011110101,
                16'b1010001000000001,
                16'b1111111111111111
            };         
              
            
            4: 
            get_maze_data = {
                16'b1111111111111111,
                16'b1000000000000001,
                16'b1011101101111101,
                16'b1010001001000101,
                16'b1011111011010101,
                16'b1010001000010101,
                16'b1010101011011101,
                16'b1010100001000101,
                16'b1000001001010101,
                16'b1111101101110101,
                16'b1000100001000101,
                16'b1011111001011101,
                16'b1000000000010001,
                16'b1011111111110101,
                16'b1000000000000101,
                16'b1111111111111111
            };
         
             
            
            5: 
            get_maze_data = {
                16'b1111111111111111,
                16'b1000000001000001,
                16'b1111101111010111,
                16'b1000100001010001,
                16'b1011101101011101,
                16'b1000100000010001,
                16'b1110111011110101,
                16'b1000100001000101,
                16'b1010001101010101,
                16'b1010101001010101,
                16'b1010101001010101,
                16'b1011101011110101,
                16'b1000101000000101,
                16'b1110101011011101,
                16'b1000001000010001,
                16'b1111111111111111
            };
         
             
            
            6: 
            get_maze_data = {
                16'b1111111111111111,
                16'b1000000000000101,
                16'b1011111011110101,
                16'b1000100000000101,
                16'b1011101111011101,
                16'b1010001001000001,
                16'b1010111001011111,
                16'b1010000011010001,
                16'b1000001001000101,
                16'b1111101101011101,
                16'b1000001001010001,
                16'b1011111011011101,
                16'b1000101001000101,
                16'b1110101011111101,
                16'b1000001000000001,
                16'b1111111111111111
            }; 
         // Add other levels similarly
         default: get_maze_data = {256{1'b1}};
         endcase
     end
 endfunction

    // Assign maze_data based on level_select
    assign maze_data = get_maze_data(level_select);

    localparam MAZE_SIZE = 16;

    // Function to compute maze index from x and y
    function integer get_maze_index;
        input [3:0] x;
        input [3:0] y;
        begin
            get_maze_index = (15 - y) * MAZE_SIZE + (15 - x);
        end
    endfunction
    
    reg visited [MAZE_SIZE-1:0][MAZE_SIZE-1:0];

    reg can_move_up, can_move_down, can_move_left, can_move_right;
    integer i, j;

    // Initialize seeker position
    initial begin
        seeker_x = 14;
        seeker_y = 14;
    end
    
    reg all_moves_blocked;
    reg loop_detected;
    reg [3:0] hider_history_x [7:0];  // Track last 8 positions
    reg [3:0] hider_history_y [7:0];
    integer history_ptr;
    reg [3:0] stationary_counter; wire clk10hz;
    // Clock divider for loop detection
    clk_divider clkloop5hz (
        .clk_in(clk),
        .m(9999999),
        .clk_out(clk10hz)
    );

    always @ (posedge clk10hz or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                hider_history_x[i] <= 0;
                hider_history_y[i] <= 0;
            end
            history_ptr <= 0;
            stationary_counter <= 0;
            loop_detected <= 0;
        end else begin
            if ((hider_x[3:0] == hider_history_x[(history_ptr - 1) % 8]) &&
                (hider_y[3:0] == hider_history_y[(history_ptr - 1) % 8])) begin
                stationary_counter <= stationary_counter + 1;
            end else begin
                stationary_counter <= 0;
            end

            if (stationary_counter >= 4) begin
                for (i = 0; i < 8; i = i + 1) begin
                    hider_history_x[i] <= 0;
                    hider_history_y[i] <= 0;
                end
                history_ptr <= 0;
            end else begin
                hider_history_x[history_ptr] <= hider_x[3:0];
                hider_history_y[history_ptr] <= hider_y[3:0];
                history_ptr <= (history_ptr + 1) % 8;
            end

            loop_detected <= (hider_history_x[0] == hider_history_x[4]) && (hider_history_y[0] == hider_history_y[4]);
        end
    end
    // Update can_move signals with boundary checks
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            can_move_up <= 0;
            can_move_down <= 0;
            can_move_left <= 0;
            can_move_right <= 0;
        end else begin
            if (seeker_y > 0)
                can_move_up <= ~maze_data[get_maze_index(seeker_x, seeker_y - 1)] && !visited[seeker_x][seeker_y - 1];
            else
                can_move_up <= 0;

            if (seeker_y < MAZE_SIZE - 1)
                can_move_down <= ~maze_data[get_maze_index(seeker_x, seeker_y + 1)] && !visited[seeker_x][seeker_y + 1];
            else
                can_move_down <= 0;

            if (seeker_x > 0)
                can_move_left <= ~maze_data[get_maze_index(seeker_x - 1, seeker_y)] && !visited[seeker_x - 1][seeker_y];
            else
                can_move_left <= 0;

            if (seeker_x < MAZE_SIZE - 1)
                can_move_right <= ~maze_data[get_maze_index(seeker_x + 1, seeker_y)] && !visited[seeker_x + 1][seeker_y];
            else
                can_move_right <= 0;
        end
    end

    wire clk2hz;

    // Clock divider for movement timing
    clk_divider clktwohz (
        .clk_in(clk),
        .m(24999999),
        .clk_out(clk2hz)
    );

    // Variables for movement logic
    reg [3:0] move_x, move_y, new_x, new_y;
    reg [4:0] current_distance, min_distance, new_distance;

    // Function to compute absolute difference
    function [4:0] abs_diff;
        input [3:0] a, b;
        begin
            if (a >= b)
                abs_diff = a - b;
            else
                abs_diff = b - a;
        end
    endfunction

    
    // Movement logic
    always @(posedge clk2hz or posedge rst) begin
        if (rst) begin
            seeker_x <= 14;
            seeker_y <= 14;
            done <= 0;
            winner <= 0;
            for (i = 0; i < MAZE_SIZE; i = i + 1) begin
                for (j = 0; j < MAZE_SIZE; j = j + 1) begin
                    visited[i][j] <= 0;
                end
            end
            all_moves_blocked <= 0;
        end else begin
            if (seeker_x == hider_x && seeker_y == hider_y) begin
                // Seeker has reached the hider, stay at current position
                seeker_x <= hider_x;
                seeker_y <= hider_y;
                done <= 1;
                winner <= 0;
            end else if (all_moves_blocked) begin
                // Reset visited array if stuck
                all_moves_blocked <= 0;
                for (i = 0; i < MAZE_SIZE; i = i + 1) begin
                    for (j = 0; j < MAZE_SIZE; j = j + 1) begin
                        visited[i][j] <= 0;
                    end
                end
            end else begin
                dir <= 0;
                visited[seeker_x][seeker_y] <= 1;
                // Compute current Manhattan distance
                current_distance = abs_diff(hider_x, seeker_x) + abs_diff(hider_y, seeker_y);
                min_distance = current_distance;

                // Initialize move_x and move_y to current position
                move_x = seeker_x;
                move_y = seeker_y;
                
                all_moves_blocked <= !(can_move_up || can_move_down || can_move_left || can_move_right);

                // Try moving up
                if (can_move_up) begin
                    new_x = seeker_x;
                    new_y = seeker_y - 1;
                    dir <= 2;
                    new_distance = abs_diff(hider_x, new_x) + abs_diff(hider_y, new_y) + (loop_detected ? history_ptr : 0);
                    if (new_distance < min_distance) begin
                        min_distance = new_distance;
                        move_x = new_x;
                        move_y = new_y;
                    end
                end

                // Try moving down
                if (can_move_down) begin
                    new_x = seeker_x;
                    new_y = seeker_y + 1;
                    dir <= 1;
                    new_distance = abs_diff(hider_x, new_x) + abs_diff(hider_y, new_y) + (loop_detected ? history_ptr : 0);
                    if (new_distance < min_distance) begin
                        min_distance = new_distance;
                        move_x = new_x;
                        move_y = new_y;
                    end
                end

                // Try moving left
                if (can_move_left) begin
                    new_x = seeker_x - 1;
                    new_y = seeker_y;
                    dir <= 2;
                    new_distance = abs_diff(hider_x, new_x) + abs_diff(hider_y, new_y) + (loop_detected ? history_ptr : 0);
                    if (new_distance < min_distance) begin
                        min_distance = new_distance;
                        move_x = new_x;
                        move_y = new_y;
                    end
                end

                // Try moving right
                if (can_move_right) begin
                    new_x = seeker_x + 1;
                    new_y = seeker_y;
                    dir <= 1;
                    new_distance = abs_diff(hider_x, new_x) + abs_diff(hider_y, new_y) + (loop_detected ? history_ptr : 0);
                    if (new_distance < min_distance) begin
                        min_distance = new_distance;
                        move_x = new_x;
                        move_y = new_y;
                    end
                end

                // If no better move found, try any available direction
                if (min_distance == current_distance) begin
                    if (can_move_up) begin
                        dir <= 2;
                        move_x = seeker_x;
                        move_y = seeker_y - 1;
                    end else if (can_move_down) begin
                        dir <= 1;
                        move_x = seeker_x;
                        move_y = seeker_y + 1;
                    end else if (can_move_left) begin
                        dir <= 2;
                        move_x = seeker_x - 1;
                        move_y = seeker_y;
                    end else if (can_move_right) begin
                        dir <= 1;
                        move_x = seeker_x + 1;
                        move_y = seeker_y;
                    end
                end

                // Update seeker position
                seeker_x <= move_x;
                seeker_y <= move_y;
            end
        end
    end

endmodule
