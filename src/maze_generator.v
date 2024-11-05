module maze_generator(
    input clk,
    input reset,
    input gen,                      // Generate button signal
    input [2:0] level_select,       // Level selection input
    output reg [7:0] bram_addr,     // 8-bit address (16x16 = 256 cells)
    output reg [8:0] bram_data_in,  // 9-bit data (0 = path, 1 = wall)
    output reg we,                  // Write enable signal
    output reg done                 // Generation done signal
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

    reg [7:0] addr_counter;  // Address counter

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bram_addr <= 0;
            we <= 0;
            done <= 0;
            addr_counter <= 0;
            bram_data_in <= 9'd1;  // Set maze to all walls (white)
        end else begin
            if (gen) begin
                bram_addr <= 0;
                we <= 1;
                done <= 0;
                addr_counter <= 0;
            end else if (we) begin
                bram_data_in <= {8'b0, maze_data[255 - addr_counter]};
                bram_addr <= addr_counter;
                if (addr_counter < 255) begin
                    addr_counter <= addr_counter + 1;
                end else begin
                    we <= 0;
                    done <= 1;
                end
            end
        end
    end
endmodule
