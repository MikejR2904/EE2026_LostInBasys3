module maze_display (
    input clk,
    input reset,
    input en,
    input [12:0] pixel_index,
    output reg [7:0] bram_addr,
    input [8:0] bram_data_out,
    input [3:0] playerX,
    input [3:0] playerY,
    input [3:0] botX,
    input [3:0] botY,
    input [2:0] chunkX,
    input [2:0] chunkY,
    input [1:0] dir,
    output reg [15:0] pixel_data
);
    wire [6:0] displayX = pixel_index % 96;
    wire [6:0] displayY = pixel_index / 96;
    /*
    Clocks
    */
    wire clk390k;
    wire clk20h;
    
    clk_divider clk390kHz (
        .clk_in(clk),
        .m(7),
        .clk_out(clk390k)
    );
    clk_divider clk20Hz ( //eventually to be brought out
        .clk_in(clk),
        .m(156249),
        .clk_out(clk20h)
    );
    
    /* 
    Maze and Display Parameters
    */
    localparam MAZE_SIZE = 16;
    localparam DISPLAY_CENTRE_X = 64;
    localparam DISPLAY_CENTRE_Y = 31;
    
    /*
    Colours
    */
    reg [15:0] black = 16'b0;
    reg [15:0] red = 16'b11111_000000_00000;
    reg [15:0] green = 16'b00000_111111_00000;
    reg [15:0] grey = 16'b01111_011111_01111;
    reg [15:0] orange = 16'b11111_011111_00000;
    reg [15:0] blue = 16'b00000_000000_11111;
    reg [15:0] white = 16'b11111_111111_11111;

    /*
    STEP 1: Based on the current player position, retrieve from the BRAM the states of all nearby cells 
    (5 in each direction from the player) creating a 11x11 square. Store this information in map_data.
    */
    reg [3:0] map_data [120:0];
    
    integer i;
    reg DELAY = 0;
    reg [6:0] counter = 0;

    always @(posedge clk390k) begin
        if (!reset) begin
            if (DELAY) begin
                map_data[counter-1] <= bram_data_out;
                DELAY = 0;
            end
            if ((playerY+counter/11 < 5) || (playerX+counter%11 < 5) || (playerY+counter/11 > 20) || (playerX+counter%11 > 20)) begin //out of range
                map_data[counter] <= 0;
            end else if ((playerY+counter/11-5 == botY) && (playerX+counter%11-5 == botX)) begin
                map_data[counter] <= 4'b1000;
            end else begin
                bram_addr <= (playerY+counter/11-5) * MAZE_SIZE + playerX+(counter%11-5);
                DELAY <= 1;
            end
            counter <= (counter == 120)? 0 : counter+1;
        end
     end
     
     /*
     STEP 2: For the 9x9 cells surrounding the player, test the walls for their connectedness. Store this in connectedness_map
     If it is a powerup/another player, store it as well.
     */
     integer current_test_pos; //the current maze array index that is being tested
     reg [6:0] connectedness; //7 bit register indicating how the wall is connected to its adjacent walls (LURD), OR what collectible it is
     reg [6:0] connectedness_map [80:0];
     
     always @(posedge clk390k) begin 
        for (i = 0; i < 81; i = i + 1) begin
            current_test_pos = (i/9+1)*11 + (i%9+1); //begin from index (1,1)
            if (map_data[current_test_pos][0]) begin //if the current object is a wall
                connectedness = {3'b0, map_data[current_test_pos-1][0], map_data[current_test_pos-11][0], map_data[current_test_pos+1][0], map_data[current_test_pos+11][0]}; //tests whether there are adjacent walls to the wall currently being tested
            end else if (map_data[current_test_pos][3:1]) begin //Collectibles and special items: Grey is 001, Green is 010, Gold is 011
                connectedness = {map_data[current_test_pos][3:1], 4'b0};
            end else if (map_data[current_test_pos][0] == 0) begin //Empty space
                connectedness = 0;
            end 
            connectedness_map[i] = connectedness;
        end
    end
    
    /*
    Wall Textures
    */
    reg [3:0] wall_selector;
    reg [2:0] special_selector;
    reg [5:0] pos_selector;
    wire [3:0] data_out;
    
    wall_textures wall_textures_mem(
        .clk(clk),
        .wall_selector(wall_selector),
        .special_selector(special_selector),
        .pos_selector(pos_selector),
        .data_out(data_out)
        );
    
    /*
    Character Animations
    */
    reg [4:0] anim_addr;
    wire [3:0] anim_data;
    
    character_textures character_textures_mem(
        .clk(clk),
        .anim_clk(clk20h),
        .dir(dir),
        .addr(anim_addr),
        .data_out(anim_data)
        );
        
    /*
    Main Display Logic
    */
    reg [3:0] data;
    reg [3:0] tileY;
    reg [3:0] tileX;
    reg WAIT = 0; //to indicate that we need to wait one cycle in order to retrieve the data
    reg ANIM_OVR = 0; //to indicate that the current pixel should be tested for animation first

    always @ (posedge clk) begin
        if (reset || !en) begin
            data = 0;
        end else if (WAIT) begin
            if (ANIM_OVR) begin
                data = anim_data;
            end if (!ANIM_OVR || anim_data == 0) begin
                data = data_out;
            end
            WAIT = 0;
            ANIM_OVR = 0;
        end else begin         
            if (((displayY-DISPLAY_CENTRE_Y)**2+(displayX-DISPLAY_CENTRE_X)**2)<=28**2) begin
                tileY = (displayY-(DISPLAY_CENTRE_Y-3-4*7)+(3-chunkY))/7;
                tileX = (displayX-(DISPLAY_CENTRE_X-3-4*7)+(3-chunkX))/7;
                if (connectedness_map[tileY*9 + tileX][6:4]) begin //Collectible
                    special_selector = connectedness_map[tileY*9 + tileX][6:4];
                    wall_selector = 4'b0;
                end else begin
                    special_selector = 3'b0;
                    wall_selector = connectedness_map[tileY*9 + tileX][3:0];
                end
                pos_selector = 48-((displayY-(DISPLAY_CENTRE_Y-3-4*7)+(3-chunkY))%7)*7-(displayX-(DISPLAY_CENTRE_X-3-4*7)+(3-chunkX))%7;
                WAIT = 1;
            end else begin
                data = 0;
            end
            
            if (displayY >= (DISPLAY_CENTRE_Y-2) && displayY <= (DISPLAY_CENTRE_Y+2) && displayX >= (DISPLAY_CENTRE_X-2) && displayX <= (DISPLAY_CENTRE_X+2)) begin
                anim_addr = (displayY-(DISPLAY_CENTRE_Y-2))*5+(displayX-(DISPLAY_CENTRE_X-2));
                WAIT = 1;
                ANIM_OVR = 1;
            end
            
            if (((displayY-DISPLAY_CENTRE_Y)**2+(displayX-DISPLAY_CENTRE_X)**2)>=28**2 && ((displayY-DISPLAY_CENTRE_Y)**2+(displayX-DISPLAY_CENTRE_X)**2)<=29**2) begin
                data = 4'b0100;
            end
        end
        
        //case -> 16 colours
        case (data)
            4'b0000: pixel_data <= black;
            4'b1111: pixel_data <= white;
            4'b0110: pixel_data <= green;
            4'b0100: pixel_data <= grey;
            4'b1100: pixel_data <= orange;
            4'b1000: pixel_data <= red;
            4'b0001: pixel_data <= blue;
        endcase
    end
endmodule
