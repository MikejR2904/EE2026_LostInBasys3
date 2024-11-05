module timer_display(input clk, reset, en, input [15:0] time_left, input [12:0] pixel_index, output reg [15:0] oled_data);
    wire [7:0] minutes = time_left / 60;
    wire [7:0] seconds = time_left % 60;
    
    wire [3:0] min_tens = minutes / 10;
    wire [3:0] min_ones = minutes % 10;
    wire [3:0] sec_tens = seconds / 10;
    wire [3:0] sec_ones = seconds % 10;
    
    localparam MIN_TENS_X = 3;
    localparam MIN_ONES_X = 8;
    localparam COLON_X = 14;
    localparam SEC_TENS_X = 18;
    localparam SEC_ONES_X = 23;
    localparam Y_START = 15;
    
    localparam BOX_X = 1;
    localparam BOX_Y = 12;
    localparam BOX_WIDTH = 29;
    localparam BOX_HEIGHT = 13;
    localparam EXPANDED_MULTIPLIER = 11;
    
    localparam BACKGROUND_DEFAULT_COLOR = 16'b00000_000000_11111;
    localparam BACKGROUND_ACTIVE_COLOR = 16'b00111_000111_00111;
    localparam TIMER_ACTIVE_COLOR = 16'b11111_00000_00000;
    localparam TIMER_DEFAULT_COLOR = 16'b11111_11111_00000;

    reg [34:0] digit_bitmap [9:0];

    initial begin
        digit_bitmap[0] = 35'b01110_10001_10001_10001_10001_10001_01110;  // Digit '0'
        digit_bitmap[1] = 35'b00100_01100_00100_00100_00100_00100_01110;  // Digit '1'
        digit_bitmap[2] = 35'b01110_10001_00001_00110_01000_10000_11111;  // Digit '2'
        digit_bitmap[3] = 35'b01110_10001_00001_00110_00001_10001_01110;  // Digit '3'
        digit_bitmap[4] = 35'b00010_00110_01010_10010_11111_00010_00010;  // Digit '4'
        digit_bitmap[5] = 35'b11111_10000_11110_00001_00001_10001_01110;  // Digit '5'
        digit_bitmap[6] = 35'b01110_10000_11110_10001_10001_10001_01110;  // Digit '6'
        digit_bitmap[7] = 35'b11111_10001_00010_00100_01000_01000_01000;  // Digit '7'
        digit_bitmap[8] = 35'b01110_10001_10001_01110_10001_10001_01110;  // Digit '8'
        digit_bitmap[9] = 35'b01110_10001_10001_01111_00001_00001_01110;  // Digit '9'
    end

    wire [6:0] x = pixel_index % 96;
    wire [6:0] y = pixel_index / 96;
    
    reg [31:0] expand_counter = 0;
    reg expanding = 0;
    wire [11:0] current_box_x = expanding ? BOX_X - (BOX_WIDTH * (EXPANDED_MULTIPLIER - 10)) / (2 * 10) : BOX_X;
    wire [11:0] current_box_y = expanding ? BOX_Y - (BOX_HEIGHT * (EXPANDED_MULTIPLIER - 10)) / (2 * 10) : BOX_Y;
    wire [11:0] current_box_width = expanding ? BOX_WIDTH * EXPANDED_MULTIPLIER / 10 : BOX_WIDTH;
    wire [11:0] current_box_height = expanding ? BOX_HEIGHT * EXPANDED_MULTIPLIER / 10 : BOX_HEIGHT;
    reg [15:0] digit_color;
    reg [15:0] box_color;

    always @ (posedge clk) begin
        if (reset) begin
            oled_data <= 16'b00000_000000_00000;
            expand_counter <= 0;
            expanding <= 0;
        end else begin
            oled_data <= 16'b00000_000000_00000;
            box_color <= (expanding) ? BACKGROUND_ACTIVE_COLOR : ((time_left == 0) ? 16'b11111_000000_00000 : BACKGROUND_DEFAULT_COLOR);
            if (current_box_x <= x && x < current_box_x + current_box_width &&
                current_box_y <= y && y < current_box_y + current_box_height) begin
                oled_data <= box_color;
            end
            if (Y_START <= y && y < Y_START + 7) begin
                digit_color <= (time_left <= 30) ? TIMER_ACTIVE_COLOR : TIMER_DEFAULT_COLOR;
                // Minutes tens digit (min_tens)
                if (MIN_TENS_X <= x && x < MIN_TENS_X + 5) begin
                    if (digit_bitmap[min_tens][(4 - (x - MIN_TENS_X)) + 5 * (6 - (y - Y_START))])
                        oled_data <= digit_color;
                end
                // Minutes ones digit (min_ones)
                if (MIN_ONES_X <= x && x < MIN_ONES_X + 5) begin
                    if (digit_bitmap[min_ones][(4 - (x - MIN_ONES_X)) + 5 * (6 - (y - Y_START))])
                        oled_data <= digit_color;
                end

                // Colon (:) between minutes and seconds
                if (COLON_X == x && (y == Y_START + 2 || y == Y_START + 4)) begin
                    oled_data <= digit_color;
                end

                // Seconds tens digit (sec_tens)
                if (SEC_TENS_X <= x && x < SEC_TENS_X + 5) begin
                    if (digit_bitmap[sec_tens][(4 - (x - SEC_TENS_X)) + 5 * (6 - (y - Y_START))])
                        oled_data <= digit_color;
                end

                // Seconds ones digit (sec_ones)
                if (SEC_ONES_X <= x && x < SEC_ONES_X + 5) begin
                    if (digit_bitmap[sec_ones][(4 - (x - SEC_ONES_X)) + 5 * (6 - (y - Y_START))])
                        oled_data <= digit_color;
                end
            end
            
            if (time_left <= 30 && time_left > 0) begin
                expand_counter <= expand_counter + 1;
                if (expand_counter == 50000000) begin
                    expanding <= ~expanding;
                    expand_counter <= 0;
                end
            end else begin
                expanding <= 0;
                expand_counter <= 0;
            end
        end
    end
endmodule
