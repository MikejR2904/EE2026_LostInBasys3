module wall_textures(
    input clk,
    input [3:0] wall_selector,
    input [2:0] special_selector,
    input [5:0] pos_selector,
    output [3:0] data_out
    );
    
    reg [48:0] wall_g = 49'b0000000_0111110_0111110_0111110_0111110_0111110_0000000; //Generic
    
    reg [48:0] wall_heart_t = 49'b0100010_1110111_1111111_1111111_0111110_0011100_0001000;
    reg [48:0] wall_curse_t = 49'b0001000_0001000_0011100_1111111_0011100_0001000_0001000;
    reg [48:0] wall_powerup_t = 49'b0001000_0010000_0100000_1111111_0000010_0000100_0001000;
    
    reg [48:0] enemy_t = 49'b0001000_0001000_0001000_1111111_0001000_0001000_0001000;
    
    reg [48:0] wall_0_t = 0;
    reg [48:0] wall_1_t = 49'b0000000_1111110_1111110_1111110_1111110_1111110_0000000; //Left
    reg [48:0] wall_2_t = 49'b0111110_0111110_0111110_0111110_0111110_0111110_0000000; //Up
    reg [48:0] wall_3_t = 49'b0000000_0111111_0111111_0111111_0111111_0111111_0000000; //Right
    reg [48:0] wall_4_t = 49'b0000000_0111110_0111110_0111110_0111110_0111110_0111110; //Down
    
    reg [48:0] wall_12_t = 49'b0111110_1111110_1111110_1111110_1111110_1111110_0000000;
    reg [48:0] wall_13_t = 49'b0000000_1111111_1111111_1111111_1111111_1111111_0000000;
    reg [48:0] wall_14_t = 49'b0000000_1111110_1111110_1111110_1111110_1111110_0111110;
    reg [48:0] wall_23_t = 49'b0111110_0111111_0111111_0111111_0111111_0111111_0000000;
    reg [48:0] wall_24_t = 49'b0111110_0111110_0111110_0111110_0111110_0111110_0111110;
    reg [48:0] wall_34_t = 49'b0000000_0111111_0111111_0111111_0111111_0111111_0111110;
    
    reg [48:0] wall_123_t = 49'b0111110_1111111_1111111_1111111_1111111_1111111_0000000;
    reg [48:0] wall_124_t = 49'b0111110_1111110_1111110_1111110_1111110_1111110_0111110;
    reg [48:0] wall_134_t = 49'b0000000_1111111_1111111_1111111_1111111_1111111_0111110;
    reg [48:0] wall_234_t = 49'b0111110_0111111_0111111_0111111_0111111_0111111_0111110;
    
    reg [48:0] wall_1234_t = 49'b0111110_1111111_1111111_1111111_1111111_1111111_0111110;
    
    reg [3:0] wall_mem [15:0][48:0];
    reg [3:0] special_mem [4:0][48:0];
    
    integer i;
    
    
    assign data_out = wall_selector ? wall_mem[wall_selector][pos_selector] : special_mem[special_selector][pos_selector];
    
    initial begin
        for (i=0; i<49; i=i+1) begin
            if (wall_0_t[i]) begin
                wall_mem[0][i] = 4'b1111;
            end else begin
                wall_mem[0][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_1_t[i]) begin
                wall_mem[8][i] = 4'b1111;
            end else begin
                wall_mem[8][i] = 4'b0000;
            end
        end

        for (i=0; i<49; i=i+1) begin
            if (wall_2_t[i]) begin
                wall_mem[4][i] = 4'b1111;
            end else begin
                wall_mem[4][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_3_t[i]) begin
                wall_mem[2][i] = 4'b1111;
            end else begin
                wall_mem[2][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_4_t[i]) begin
                wall_mem[1][i] = 4'b1111;
            end else begin
                wall_mem[1][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_12_t[i]) begin
                wall_mem[12][i] = 4'b1111;
            end else begin
                wall_mem[12][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_13_t[i]) begin
                wall_mem[10][i] = 4'b1111;
            end else begin
                wall_mem[10][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_14_t[i]) begin
                wall_mem[9][i] = 4'b1111;
            end else begin
                wall_mem[9][i] = 4'b0000;
            end
        end

        for (i=0; i<49; i=i+1) begin
            if (wall_23_t[i]) begin
                wall_mem[6][i] = 4'b1111;
            end else begin
                wall_mem[6][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_24_t[i]) begin
                wall_mem[5][i] = 4'b1111;
            end else begin
                wall_mem[5][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_34_t[i]) begin
                wall_mem[3][i] = 4'b1111;
            end else begin
                wall_mem[3][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_123_t[i]) begin
                wall_mem[14][i] = 4'b1111;
            end else begin
                wall_mem[14][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_124_t[i]) begin
                wall_mem[13][i] = 4'b1111;
            end else begin
                wall_mem[13][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_134_t[i]) begin
                wall_mem[11][i] = 4'b1111;
            end else begin
                wall_mem[11][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_234_t[i]) begin
                wall_mem[7][i] = 4'b1111;
            end else begin
                wall_mem[7][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin
            if (wall_1234_t[i]) begin
                wall_mem[15][i] = 4'b1111;
            end else begin
                wall_mem[15][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin ///Grey
            if (wall_curse_t[i]) begin
                special_mem[1][i] = 4'b0100;
            end else begin
                special_mem[1][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin ///Green
            if (wall_heart_t[i]) begin
                special_mem[2][i] = 4'b0110;
            end else begin
                special_mem[2][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin ///Gold
            if (wall_powerup_t[i]) begin
                special_mem[3][i] = 4'b1100;
            end else begin
                special_mem[3][i] = 4'b0000;
            end
        end
        
        for (i=0; i<49; i=i+1) begin ///Blue
            if (enemy_t[i]) begin
                special_mem[4][i] = 4'b0001;
            end else begin
                special_mem[4][i] = 4'b0000;
            end
        end
    end
endmodule
