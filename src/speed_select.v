module speed_select(input sysclk, reset, en, power_up_active, curse_active, input [10:0] energy, input [7:0] speed_setting, output reg velocity_clk = 0);
    reg [31:0] count = 0;
    reg [31:0] max_count = 99_999_999;
    
    wire [31:0] SPEEDLIMIT; 
    assign SPEEDLIMIT = speed_setting == 1 ? TIMELIMIT1 :
                   speed_setting == 2 ? TIMELIMIT2 :
                   speed_setting == 3 ? TIMELIMIT3 :
                   speed_setting == 4 ? TIMELIMIT4 :
                   speed_setting == 5 ? TIMELIMIT5 : 
                    TIMELIMIT3;

    localparam FAST_SPEED = 2_272_726; //22Hz
    localparam NORM_SPEED = 2_777_776; //18Hz 
    localparam NORM_SPEED_SLOW = 3_333_332; //15Hz
    
    always @ (posedge sysclk) begin
        if (reset) begin
            velocity_clk <= 0;
            max_count <= NORM_SPEED / 3; //Factor of 3 is because the movement control is tri-state
        end else if (en) begin
            if (power_up_active) begin
                max_count <= FAST_SPEED / 3;
            end else if (!power_up_active && curse_active) begin
                max_count <= (energy > 3) ? NORM_SPEED * 5 / 12 : NORM_SPEED_SLOW * 5 / 12;
            end else begin
                max_count <= (energy > 3) ? NORM_SPEED / 3 : NORM_SPEED_SLOW / 3;
            end
            count <= (count == max_count) ? 0 : count + 1;
            velocity_clk <= (count == 0) ? ~velocity_clk : velocity_clk;
        end
    end
endmodule
