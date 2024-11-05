module energy_bar_display(input clk, reset, input [10:0] energy, input [12:0] pixel_index, output reg [15:0] oled_data);
    localparam GREEN = 16'h07E0;
    localparam YELLOW = 16'hFFE0;
    localparam RED = 16'hF800;
    localparam GREY = 16'h8410;
    
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;
    
    localparam BAR_WIDTH = 10;
    localparam BAR_HEIGHT = 2; 
    localparam GAP_HEIGHT = 1;   // Gap height between bars
    localparam BAR_WITH_GAP = BAR_HEIGHT + GAP_HEIGHT; // Total height of each bar and gap
    localparam NUM_BARS = 10;
    localparam BAR_DISPLAY_HEIGHT = 60;
    
    wire [6:0] x = pixel_index % SCREEN_WIDTH;
    wire [6:0] y = pixel_index / SCREEN_WIDTH;
    
    integer bar_num;
    integer bar_y_start;

    always @ (posedge clk) begin
        oled_data = 16'h0000;
        if (x >= 2 && x < BAR_WIDTH && y >= BAR_DISPLAY_HEIGHT - (NUM_BARS * BAR_WITH_GAP) && y < BAR_DISPLAY_HEIGHT) begin
            bar_num <= (BAR_DISPLAY_HEIGHT - y - 1) / BAR_WITH_GAP;
            bar_y_start <= BAR_DISPLAY_HEIGHT - (bar_num + 1) * BAR_WITH_GAP;
            if (y >= bar_y_start && y < bar_y_start + BAR_HEIGHT) begin
                if (bar_num < energy) begin
                    if (energy > 6) begin
                        oled_data <= GREEN;
                    end else if (energy > 3 && energy <= 6) begin
                        oled_data <= YELLOW;
                    end else begin
                        oled_data <= RED;
                    end
                end else begin
                    // Inactive energy bars (above the current energy level)
                    oled_data <= GREY;
                end
            end
        end
    end
    
endmodule
