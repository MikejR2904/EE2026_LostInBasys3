module speed_select(input sysclk, reset, en, power_up_active, curse_active, input [31:0] speed_limit, input [10:0] energy, output reg velocity_clk = 0);
    reg [31:0] count = 0;
    reg [31:0] max_count = 99_999_999;

    // localparam FAST_SPEED = 2_272_726; //22Hz
    // localparam NORM_SPEED = 2_777_776; //18Hz 
    // localparam NORM_SPEED_SLOW = 3_333_332; //15Hz
    reg[31:0] FAST_SPEED, NORM_SPEED, NORM_SPEED_SLOW;

    always @(*) begin
        NORM_SPEED = speed_limit;
        FAST_SPEED = NORM_SPEED - 50_000;
        NORM_SPEED_SLOW = NORM_SPEED + 50_000;
    end
    
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
