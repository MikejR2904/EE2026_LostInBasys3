module player_movement(
    input sysclk,
    input reset,
    input en,
    input [3:0] initial_player_x,
    input [3:0] initial_player_y,
    input [8:0] bram_dout,
    input [4:0] PB,
    input speed_limit,
    output reg [3:0] playerX,
    output reg [3:0] playerY,
    output reg [2:0] chunkX,
    output reg [2:0] chunkY,
    output reg [1:0] dir,
    output reg [7:0] bram_addr,
    output reg we_player,
    output reg [8:0] bram_din_player,
    output reg [7:0] bram_addr_player,
    output [10:0] energy
);
    reg [2:0] collectible_type;
    wire curse_active;
    wire powerup_active;
    
    energy_level energy_level_module (
    .clk(sysclk), 
    .reset(reset), 
    .en(en), 
    .dir(dir),
    .collectible_type(collectible_type), 
    .energy(energy),
    .power_up_active(powerup_active), 
    .curse_active(curse_active)
    );
    
    
    wire mvmt_clk;
    speed_select speed_select_module(
        .sysclk(sysclk),
        .reset(reset),
        .en(en),
        .speed_limit(speed_limit),
        .power_up_active(powerup_active),
        .curse_active(curse_active),
        .energy(energy),
        .velocity_clk(mvmt_clk)
        );
        
    
    reg [7:0] addr_to_test;
    localparam MAZE_SIZE = 16;
    
    reg player_initialized;
    reg [2:0] player_state;
    parameter IDLE = 3'b000, WAITING = 3'b001, MOVE = 3'b010, CHECK = 3'b011;
    
    always @(posedge mvmt_clk or posedge reset) begin //clock 
        if (reset) begin
            player_state <= IDLE;
            player_initialized <= 0;
            playerX <= initial_player_x;
            playerY <= initial_player_y;
            chunkX <= 3;
            chunkY <= 3;
            we_player <= 0;
        end else if (en) begin
            if (!player_initialized) begin
                playerX <= initial_player_x;
                playerY <= initial_player_y;
                chunkX <= 3;
                chunkY <= 3;
                player_initialized <= 1;
            end

            case (player_state)
                IDLE: begin
                    we_player <= 0;
                    dir <= 0;
                    collectible_type <= 0;
                    if (PB[4:1]) begin
                        player_state <= WAITING;
                    end
                end
                WAITING: begin
                    // Compute next position based on current_direction
                    //bram_wait <= 0;
                    if (PB[1]) begin //up
                        bram_addr <= (playerY-1) * MAZE_SIZE + playerX;
                    end else if (PB[2]) begin //left
                        bram_addr <= playerY * MAZE_SIZE + playerX-1;
                    end else if (PB[3]) begin //right
                        bram_addr <= playerY * MAZE_SIZE + playerX+1;
                    end else if (PB[4]) begin //down
                        bram_addr <= (playerY+1) * MAZE_SIZE + playerX;
                    end
                    player_state <= MOVE;
                end
                MOVE: begin
                    dir <= 0;
                    collectible_type <= 0;
                    if (energy) begin
                        if (PB[1]) begin //up
                            if (chunkY != 6 || bram_dout[0] == 0) begin
                                dir <= 2;
                                chunkY <= chunkY==6 ? 0 : chunkY+1;
                                if (chunkY == 6) begin
                                    playerY <= playerY - 1;
                                    if (bram_dout[3:1]) begin
                                        case (bram_dout[3:1])
                                            3'b001: collectible_type = 2;
                                            3'b010: collectible_type = 3;
                                            3'b011: collectible_type = 4;
                                        endcase
                                        we_player <= 1;
                                        bram_din_player <= {5'b0, 3'b000, bram_dout[0]}; // Keep wall bit, clear collectible bits
                                        bram_addr_player <= bram_addr; //this is not necessary actually
                                    end
                                end
                            end else begin
                                dir <= 0;
                            end     
                        end else if (PB[2]) begin //left
                            if (chunkX != 6 || bram_dout[0] == 0) begin
                                dir <= 2;
                                chunkX <= chunkX==6 ? 0 : chunkX+1;
                                if (chunkX == 6) begin
                                    playerX <= playerX - 1;
                                    if (bram_dout[3:1]) begin
                                        case (bram_dout[3:1])
                                            3'b001: collectible_type <= 2;
                                            3'b010: collectible_type <= 3;
                                            3'b011: collectible_type <= 4;
                                        endcase
                                        we_player <= 1;
                                        bram_din_player <= {5'b0, 3'b000, bram_dout[0]}; // Keep wall bit, clear collectible bits
                                        bram_addr_player <= bram_addr; //this is not necessary actually
                                    end
                                end
                            end else begin
                                dir <= 0;
                            end  
                        end else if (PB[3]) begin //right
                            if (chunkX != 0 || bram_dout[0] == 0) begin 
                                dir <= 1; 
                                chunkX <= chunkX==0 ? 6 : chunkX-1;
                                if (chunkX == 0) begin
                                    playerX <= playerX + 1;
                                    if (bram_dout[3:1]) begin
                                        case (bram_dout[3:1])
                                            3'b001: collectible_type <= 2;
                                            3'b010: collectible_type <= 3;
                                            3'b011: collectible_type <= 4;
                                        endcase
                                        we_player <= 1;
                                        bram_din_player <= {5'b0, 3'b000, bram_dout[0]}; // Keep wall bit, clear collectible bits
                                        bram_addr_player <= bram_addr; //this is not necessary actually
                                    end
                                end
                            end else begin
                                dir <= 0;
                            end  
                        end else if (PB[4]) begin //down
                            if (chunkY != 0 || bram_dout[0] == 0) begin
                                dir <= 1; 
                                chunkY <= chunkY==0 ? 6 : chunkY-1;
                                if (chunkY == 0) begin
                                    playerY <= playerY + 1;
                                    if (bram_dout[3:1]) begin
                                        case (bram_dout[3:1])
                                            3'b001: collectible_type <= 2;
                                            3'b010: collectible_type <= 3;
                                            3'b011: collectible_type <= 4;
                                        endcase
                                        we_player <= 1;
                                        bram_din_player <= {5'b0, 3'b000, bram_dout[0]}; // Keep wall bit, clear collectible bits
                                        bram_addr_player <= bram_addr; //this is not necessary actually
                                    end
                                end
                            end else begin
                                dir <= 0;
                            end  
                        end else begin
                            dir <= 0;
                        end
                        player_state <= IDLE;
                    end
                    else begin
                        dir <= 0;
                        player_state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
