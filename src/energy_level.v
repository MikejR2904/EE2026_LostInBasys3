module energy_level(input clk, reset, en, input [1:0] dir, input [2:0] collectible_type, output reg [10:0] energy, output reg power_up_active, output reg curse_active);
    localparam MAX_ENERGY = 10;
    localparam RECHARGE_RATE = 5;
    localparam CONSUMPTION_RATE = 10;
    localparam SCALE_FACTOR = 10;
    localparam POWER_UP_TIME = 32'd500000000;
    localparam CURSE_TIME = 32'd400000000; 
    
    reg [20:0] scaled_energy = MAX_ENERGY * SCALE_FACTOR;
    reg [31:0] time_counter = 0;
    reg [31:0] power_up_timer = POWER_UP_TIME; 
    reg [31:0] curse_timer = CURSE_TIME; 
    reg [31:0] recharge_rate = RECHARGE_RATE;
    reg [31:0] consumption_rate = CONSUMPTION_RATE;  
    
    always @ (posedge clk) begin
        if (reset) begin
            scaled_energy <= MAX_ENERGY * SCALE_FACTOR;
            time_counter <= 0;
            power_up_timer <= POWER_UP_TIME;
            curse_timer <= CURSE_TIME;
            power_up_active <= 0;
            curse_active <= 0;
            recharge_rate <= RECHARGE_RATE;
            consumption_rate <= CONSUMPTION_RATE;
            energy <= MAX_ENERGY;
        end else begin
            if (en) begin
                if (power_up_active) begin
                    if (power_up_timer > 0 && time_counter < 99999999) begin
                        power_up_timer <= power_up_timer - 1;
                        time_counter <= time_counter + 1;
                    end else if (power_up_timer > 0 && time_counter == 99999999) begin
                        power_up_timer <= power_up_timer - 1;
                        time_counter <= 0;
                        if (scaled_energy + recharge_rate <= MAX_ENERGY * SCALE_FACTOR) begin
                            scaled_energy <= scaled_energy + recharge_rate; // Recharge energy
                        end else begin
                            scaled_energy <= MAX_ENERGY * SCALE_FACTOR; // Cap energy at max
                        end
                    end else begin
                        power_up_active <= 0;
                        time_counter <= 0;
                        power_up_timer <= POWER_UP_TIME;
                        recharge_rate <= RECHARGE_RATE;
                    end
                end
                
                if (!power_up_active && curse_active) begin
                    if (curse_timer > 0 && time_counter < 99999999) begin
                        curse_timer <= curse_timer - 1;
                        time_counter <= time_counter + 1;
                    end else if (curse_timer > 0 && time_counter == 99999999) begin
                        curse_timer <= curse_timer - 1;
                        time_counter <= 0;
                        if (scaled_energy >= consumption_rate) begin
                            scaled_energy <= scaled_energy - consumption_rate;
                        end else begin
                            scaled_energy <= 0; // Cap energy at 0
                        end
                    end else begin
                        curse_active <= 0;
                        curse_timer <= CURSE_TIME;
                        time_counter <= 0;
                        consumption_rate <= CONSUMPTION_RATE;
                    end
                end
                if ((dir != 0) && !power_up_active && !curse_active) begin
                    if (time_counter < 99999999) begin
                        time_counter <= time_counter + 1;
                    end else begin
                        time_counter <= 0;
                        if (scaled_energy >= consumption_rate) begin
                            scaled_energy <= scaled_energy - consumption_rate;
                        end else begin
                            scaled_energy <= 0; // Cap energy at 0
                        end
                    end
                end else if ((dir == 0) && !power_up_active && !curse_active) begin
                    if (time_counter < 99999999) begin
                        time_counter <= time_counter + 1;
                    end else begin
                        time_counter <= 0;
                        if (scaled_energy + recharge_rate <= MAX_ENERGY * SCALE_FACTOR) begin
                            scaled_energy <= scaled_energy + recharge_rate; // Recharge energy
                        end else begin
                            scaled_energy <= MAX_ENERGY * SCALE_FACTOR; // Cap energy at max
                        end
                    end
                end
                
                case (collectible_type)
                    3: begin // Heart (heal)
                        scaled_energy <= MAX_ENERGY * SCALE_FACTOR; // Instantly recharge energy to max
                    end
    
                    4: begin // 5-Point Star (Power-up)
                        if (!power_up_active) begin
                            power_up_active <= 1;
                            curse_active <= 0;
                            power_up_timer <= POWER_UP_TIME;
                            recharge_rate <= RECHARGE_RATE * 2;  // Double recharge rate
                        end
                    end
    
                    2: begin // 4-Point Star (Curse)
                        if (!curse_active && !power_up_active) begin
                            curse_active <= 1;
                            curse_timer <= CURSE_TIME;
                            consumption_rate <= (dir != 0) ? CONSUMPTION_RATE * 2 : 0;  // Double consumption rate
                        end
                    end
                endcase
    
                energy <= scaled_energy / SCALE_FACTOR;
            end
        end
    end
endmodule
