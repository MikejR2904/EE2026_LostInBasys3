module character_textures(
    input clk,
    input anim_clk,
    input [1:0] dir,
    input [4:0] addr,
    output reg [3:0] data_out
    );
    
    reg [3:0] display_character [24:0];
    
    always @ (posedge clk) begin
        data_out = display_character[addr];
    end
    
    initial begin
        display_character[0] = 4'b0000;
        display_character[1] = 4'b0000;
        display_character[2] = 4'b1000;
        display_character[3] = 4'b0000;
        display_character[4] = 4'b0000;
        
        display_character[5] = 4'b0000;
        display_character[6] = 4'b1000;
        display_character[7] = 4'b1000;
        display_character[8] = 4'b1000;
        display_character[9] = 4'b0000;
        
        display_character[10] = 4'b1000;
        display_character[11] = 4'b1000;
        display_character[12] = 4'b1111;
        display_character[13] = 4'b1111;
        display_character[14] = 4'b0000;
        
        display_character[15] = 4'b1000;
        display_character[16] = 4'b1000;
        display_character[17] = 4'b1000;
        display_character[18] = 4'b1000;
        display_character[19] = 4'b0000;
        
        display_character[20] = 4'b0000;
        display_character[21] = 4'b1000;
        display_character[22] = 4'b0000;
        display_character[23] = 4'b1000;
        display_character[24] = 4'b0000;
    end
    
    always @ (posedge anim_clk) begin
        if (dir == 0) begin
            display_character[21] <= 4'b1000;
            display_character[22] <= 4'b0000;
            display_character[23] <= 4'b1000;
        end else if (dir == 1) begin
            display_character[10] <= 4'b1000;
            display_character[11] <= 4'b1000;
            display_character[12] <= 4'b1111;
            display_character[13] <= 4'b1111;
            display_character[14] <= 4'b0000;
            
            display_character[15] <= 4'b1000;
            display_character[16] <= 4'b1000;
            display_character[17] <= 4'b1000;
            display_character[18] <= 4'b1000;
            display_character[19] <= 4'b0000;
            
            display_character[22] <= ~display_character[22] & 4'b1000;
            display_character[23] <= ~display_character[23] & 4'b1000;
        end else if (dir == 2) begin
            display_character[10] <= 4'b0000;
            display_character[11] <= 4'b1111;
            display_character[12] <= 4'b1111;
            display_character[13] <= 4'b1000;
            display_character[14] <= 4'b1000;
            
            display_character[15] <= 4'b0000;
            display_character[16] <= 4'b1000;
            display_character[17] <= 4'b1000;
            display_character[18] <= 4'b1000;
            display_character[19] <= 4'b1000;
            
            display_character[21] <= ~display_character[21] & 4'b1000;
            display_character[22] <= ~display_character[22] & 4'b1000;
        end
    end
endmodule
