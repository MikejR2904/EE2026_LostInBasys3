module compass_display(input clk, reset, en, input signed [11:0] x_seeker, y_seeker, x_hider, y_hider, input [12:0] pixel_index, output reg [15:0] oled_data);
    parameter OLED_WIDTH = 96;
    parameter OLED_HEIGHT = 64;
    parameter BACKGROUND_COLOR = 16'h0;
    parameter CENTER_X = 64;   // X-coordinate of circle center
    parameter CENTER_Y = 32;   // Y-coordinate of circle center
    parameter LENGTH = 20;     // Length of a full compass bar
    parameter WIDTH = 2;       // Width of a full compass bar
    parameter SEEKER_SIGHT_RADIUS = 27;
    parameter HIDER_SIGHT_RADIUS = 31;
    
    wire [8:0] x; 
    wire [8:0] y;
    reg [11:0] x_mid, y_mid;
    assign x = pixel_index % OLED_WIDTH;
    assign y = pixel_index / OLED_WIDTH;
    always @ (posedge clk) begin
        if (x_hider != x_seeker && y_hider != y_seeker) begin
            // Calculate x_mid and y_mid using slope (prevent division by zero issues)
            if (y_hider > y_seeker) begin
                x_mid <= CENTER_X + 31 * (x_hider - x_seeker) / (y_hider - y_seeker);
            end else begin
                x_mid <= CENTER_X + 31 * (x_hider - x_seeker) / (y_seeker - y_hider);
            end
            if (x_hider > x_seeker) begin
                y_mid <= CENTER_Y - 31 * (y_hider - y_seeker) / (x_hider - x_seeker);
            end else begin
                y_mid <= CENTER_Y - 31 * (y_hider - y_seeker) / (x_seeker - x_hider);
            end
        end else if (x_hider != x_seeker) begin
            // Handle horizontal bar (when y_diff = 0)
            x_mid <= (x_hider > x_seeker) ? CENTER_X + 31 : CENTER_X - 31;
            y_mid <= CENTER_Y; // No vertical movement
        end else if (y_hider != y_seeker) begin
            // Handle vertical bar (when x_diff = 0)
            x_mid <= CENTER_X; // No horizontal movement
            y_mid <= (y_hider > y_seeker) ? CENTER_Y + 31 : CENTER_Y - 31;
        end
    end
    
    parameter r_disappear = 6;
    parameter r_green = 9;
    parameter r_red = 12;
    
    wire [31:0] radius_square = (x_hider - x_seeker) * (x_hider - x_seeker) + (y_hider - y_seeker) * (y_hider - y_seeker);
    
    wire [11:0] scaled_tan_30 = 12'd577;
    wire [11:0] scaled_tan_60 = 12'd1732;
    
    wire signed [11:0] x_diff = x_hider - x_seeker;
    wire signed [11:0] negx_diff = x_seeker - x_hider;
    wire signed [11:0] y_diff = y_hider - y_seeker;
    wire signed [11:0] negy_diff = y_seeker - y_hider;
    
    wire signed [22:0] scaled_x_diff_1 = 1000 * x_diff;
    wire signed [22:0] scaled_x_diff_2 = 1000 * negx_diff;
    wire signed [22:0] scaled_y_diff_1 = 1000 * y_diff;
    wire signed [22:0] scaled_y_diff_2 = 1000 * negy_diff;
    wire signed [22:0] tan_60_y_diff_1 = scaled_tan_60 * y_diff;
    wire signed [22:0] tan_60_y_diff_2 = scaled_tan_60 * negy_diff;
    wire signed [22:0] tan_30_y_diff_1 = scaled_tan_30 * y_diff;
    wire signed [22:0] tan_30_y_diff_2 = scaled_tan_30 * negy_diff;
    
    wire angle_30_330 = ((x_hider > x_seeker) && ((scaled_x_diff_1 > tan_60_y_diff_1) && (scaled_x_diff_1 > tan_60_y_diff_2)));
    wire angle_30_60 = ((x_hider > x_seeker) && (y_hider > y_seeker) && ((scaled_x_diff_1 < tan_60_y_diff_1) && (scaled_x_diff_1 > tan_30_y_diff_1)));
    wire angle_60_120 = ((y_hider > y_seeker) && ((tan_30_y_diff_1 > scaled_x_diff_1) && (tan_30_y_diff_1 > scaled_x_diff_2)));
    wire angle_120_150 = ((x_seeker > x_hider) && (y_hider > y_seeker) && ((tan_30_y_diff_1 < scaled_x_diff_2) && (tan_60_y_diff_1 > scaled_x_diff_2)));
    wire angle_150_210 = ((x_seeker > x_hider) && ((scaled_x_diff_2 > tan_60_y_diff_1) && (scaled_x_diff_2 > tan_60_y_diff_2)));
    wire angle_210_240 = ((x_seeker > x_hider) && (y_seeker > y_hider) && ((scaled_x_diff_2 < tan_60_y_diff_2) && (scaled_x_diff_2 > tan_30_y_diff_2)));
    wire angle_240_300 = ((y_seeker > y_hider) && ((tan_30_y_diff_2 > scaled_x_diff_1) && (tan_30_y_diff_2 > scaled_x_diff_2)));
    wire angle_300_330 = ((x_hider > x_seeker) && (y_seeker > y_hider) && ((tan_30_y_diff_2 < scaled_x_diff_1) && (tan_60_y_diff_2 > scaled_x_diff_1)));
    
    function [15:0] get_color;
        input [15:0] radius_square;
        reg [15:0] color; // Variable to store the color

        begin
            if (radius_square > r_red * r_red) begin
                color = 16'hF800;
            end else if (radius_square < r_disappear * r_disappear) begin
                color = BACKGROUND_COLOR;
            end else if (radius_square < r_green * r_green) begin
                color = 16'b00000_111111_00000;
            end else if ((radius_square < r_red * r_red) && (radius_square > r_green * r_green)) begin
                if (radius_square < (r_green * r_green + ((r_red * r_red - r_green * r_green) / 6))) begin
                    color = 16'b00001_111110_00000;
                end else if (radius_square < (r_green * r_green + 2 * ((r_red * r_red - r_green * r_green) / 6))) begin
                    color = 16'b00011_111100_00000;
                end else if (radius_square < (r_green * r_green + 3 * ((r_red * r_red - r_green * r_green) / 6))) begin
                    color = 16'b00111_111000_00000;
                end else if (radius_square < (r_green * r_green + 4 * ((r_red * r_red - r_green * r_green) / 6))) begin
                    color = 16'b01111_110000_00000;
                end else if (radius_square < (r_green * r_green + 5 * ((r_red * r_red - r_green * r_green) / 6))) begin
                    color = 16'b11111_100000_00000;
                end 
            end
            
            get_color = color; // Return the calculated color value
        end
     endfunction
    
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            oled_data <= BACKGROUND_COLOR;
        end else if (en) begin
            if (angle_30_60 && ((x >= 79 && x < 94 && y >= 1 && y < 3)||(x >= 93 && x < 95 && y >= 1 && y < 16))) begin
                oled_data <= get_color(radius_square);
            end else if (angle_120_150 && ((x >= 32 && x < 47 && y >= 1 && y < 3)||(x >= 32 && x < 34 && y >= 1 && y < 16))) begin
                oled_data <= get_color(radius_square);
            end else if (angle_210_240 && ((x >= 32 && x < 47 && y >= 61 && y < 63)||(x >= 32 && x < 34 && y >= 48 && y < 63))) begin
                oled_data <= get_color(radius_square);
            end else if (angle_300_330 && ((x >= 79 && x < 94 && y >= 61 && y < 63)||(x >= 93 && x < 95 && y >= 48 && y < 63))) begin
                oled_data <= get_color(radius_square);
            end else if (angle_60_120 && y >= 1 && y < 3 && (x >= x_mid - LENGTH/2 && x < x_mid + LENGTH/2)) begin
                oled_data <= get_color(radius_square);
            end else if (angle_30_330 && x >= 93 && x < 95 && (y >= y_mid - LENGTH/2 && y < y_mid + LENGTH/2)) begin
                oled_data <= get_color(radius_square);
            end else if (angle_150_210 && x >= 32 && x < 34 && (y >= y_mid - LENGTH/2 && y < y_mid + LENGTH/2)) begin
                oled_data <= get_color(radius_square);
            end else if (angle_240_300 && y >= 61 && x < 63 && (x >= x_mid - LENGTH/2 && x < x_mid + LENGTH/2)) begin
                oled_data <= get_color(radius_square);
            end else begin
                oled_data <= BACKGROUND_COLOR;
            end
        end
    end
endmodule
