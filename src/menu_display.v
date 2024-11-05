module menu_display(
    input wire clk,             // 100MHz system clock
    input wire reset,
    input wire btnU,            // Up button
    input wire btnD,            // Down button
    input wire btnC,            // Center button
    input wire btnL,            // Left button
    input wire btnR,            // Right button
    input wire game_done,
    input wire winner,
    output reg game_started = 0,
    output reg [7:0] time_setting = 2,
    output reg [7:0] speed_setting = 3,
    input [12:0] pixel_index, 
    output reg [15:0] pixel_color      // OLED connections
);
    
    // Clock generation
    wire clk6p25m;                
    wire clk_25MHz;
    clk_divider_mod clk_6p25m (clk, 7, clk6p25m);
    clk_divider_mod generate_clk25Mhz (clk, 1, clk_25MHz);

    // Button debouncing
    wire btnU_db, btnD_db, btnC_db, btnL_db, btnR_db;
    debounce_a dbU (.clk(clk), .btn_in(btnU), .btn_out(btnU_db));
    debounce_a dbD (.clk(clk), .btn_in(btnD), .btn_out(btnD_db));
    debounce_a dbC (.clk(clk), .btn_in(btnC), .btn_out(btnC_db));
    debounce_a dbL (.clk(clk), .btn_in(btnL), .btn_out(btnL_db));
    debounce_a dbR (.clk(clk), .btn_in(btnR), .btn_out(btnR_db));

    // Constants for OLED display
    localparam BLACK = 16'h0000;
    localparam RED = 16'hF800;
    localparam ORANGE = 16'hFC00;
    localparam GREEN = 16'h07E0;
    localparam BLUE = 16'h001F;
    localparam WHITE = 16'hFFFF;

    // Menu parameters (from your original code)
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;

    // States
    localparam MENU_OPTION_COUNT = 2;
    localparam SETTINGS_OPTION_COUNT = 3;
    localparam STATE_MENU = 2'b00;
    localparam STATE_GAME = 2'b01;
    localparam STATE_SETTINGS = 2'b10;
    localparam STATE_FINAL = 2'b11;

    // Game state registers
    reg [1:0] current_state;
    reg [1:0] menu_selection;
    reg [1:0] settings_selection;
           
    // Pixel coordinates
    wire [6:0] x;
    wire [5:0] y;
    assign x = pixel_index % SCREEN_WIDTH;
    assign y = pixel_index / SCREEN_WIDTH;
    
         // Image parameters
    parameter IMAGE_WIDTH = 96;   // Replace with your image width
    parameter IMAGE_HEIGHT = 64;  // Replace with your image height
    parameter IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;
    integer img_x, img_y, img_index;
    
    // SETTINGS PAGE 
    localparam TIME_MIN = 1;
    localparam TIME_MAX = 4;
    localparam SPEED_MIN = 1;
    localparam SPEED_MAX = 5;
    
    // Scale properties
    localparam SCALE_LENGTH = 35;  // Length of the scale in pixels
    localparam SCALE_X_START = 43;
    localparam SCALE_Y_TIME = 25;  // Y-coordinate of the scale
    localparam SCALE_Y_SPEED = 40;  // Y-coordinate of the scale
    
    localparam TIME_DIGIT_X = SCALE_X_START + SCALE_LENGTH + 10; 
    localparam TIME_DIGIT_Y = SCALE_Y_TIME - 4;                 
    localparam SPEED_DIGIT_X = SCALE_X_START + SCALE_LENGTH + 10; 
    localparam SPEED_DIGIT_Y = SCALE_Y_SPEED - 4;   
    
    // Bitmap for the movable point (5x5 square)
    reg [24:0] point_bitmap = 25'b11111_11111_11111_11111_11111;
    integer bitmap_x, bitmap_y;
    integer font_data;


    // Position of the point on the scale
    integer point_position_time, point_position_speed;
    
    //calculate point position
    always @(*) begin
        if (settings_selection == 0) begin
            // Adjusting time setting
            point_position_time = SCALE_X_START + ((time_setting - TIME_MIN) * SCALE_LENGTH) / (TIME_MAX - TIME_MIN);
        end else if (settings_selection == 1) begin
            // Adjusting speed setting
            point_position_speed = SCALE_X_START + ((speed_setting - SPEED_MIN) * SCALE_LENGTH) / (SPEED_MAX - SPEED_MIN);
        end
    end


        // Declaration of BRAM signals
    reg [12:0] bram_addr; // Common address for all BRAMs
    wire [15:0] menu_start_data;
    wire [15:0] menu_settings_data;
    wire [15:0] setting_time_data;
    wire [15:0] setting_speed_data;
    wire [15:0] setting_return_data;
    wire [15:0] seeker_win;
    wire [15:0] hider_win;
    
    // Instantiate BRAMs
    
    // Menu Start BRAM
    menu_start_bram menu_start_bram_inst (
        .clka(clk_25MHz),             // Clock input
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),                 // Data input tied to zero (not used)
        .douta(menu_start_data)  // Data 
    );
    
    // Menu Settings BRAM
    menu_settings_bram menu_settings_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),    
        .douta(menu_settings_data)
    );
    
    
    // Settings Time BRAM
    settings_time_bram setting_time_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),    
        .douta(setting_time_data)
    );
    
    // Settings Speed BRAM
    settings_speed_bram setting_speed_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),   
        .douta(setting_speed_data)
    );
    
    // Settings Return BRAM
    settings_return_bram setting_return_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),   
        .douta(setting_return_data)
    );
    
    hider_win_bram hider_win_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),   
        .douta(hider_win)
    );
    
    seeker_win_bram seeker_win_bram_inst (
        .clka(clk_25MHz),    
        .ena(1'b1),                   // Enable tied high to always enable
        .wea(1'b0),                   // Write enable tied low to disable writes
        .addra(bram_addr),            // Address input
        .dina(16'b0),   
        .douta(seeker_win)
    );
    // Registers to handle BRAM data and latency
    reg [15:0] selected_bram_data;
    reg [15:0] selected_bram_data_reg;
    
     //OLED display logic
    always @(posedge clk_25MHz) begin
        img_x <= x;
        img_y <= y;
        img_index <= img_y * IMAGE_WIDTH + img_x; // Address calculation
    
        // Calculate BRAM address
        if (img_x < IMAGE_WIDTH && img_y < IMAGE_HEIGHT) begin
            bram_addr <= img_index[12:0]; // Ensure address width matches
        end else begin
            bram_addr <= 0; // Default address
        end
      
        case (current_state)
            STATE_MENU: begin
                if (menu_selection == 0) begin
                    selected_bram_data <= menu_start_data;
                end else if (menu_selection == 1) begin
                    selected_bram_data <= menu_settings_data;
                end
                pixel_color <= selected_bram_data;
            end
            
            STATE_SETTINGS: begin
                // Select the appropriate settings image
                if (settings_selection == 0) begin
                    selected_bram_data <= setting_time_data;
                end else if (settings_selection == 1) begin
                    selected_bram_data <= setting_speed_data;
                end else if (settings_selection == 2) begin
                    selected_bram_data <= setting_return_data;
                end
                // Start with the BRAM data

                
                if (x >= point_position_time - 2 && x <= point_position_time + 2 && y >= SCALE_Y_TIME - 2 && y <= SCALE_Y_TIME + 2) begin
                    // Extract the bitmap pixel data
                    bitmap_x = x - (point_position_time - 2);
                    bitmap_y = y - (SCALE_Y_TIME - 2);
                    if (point_bitmap[bitmap_y * 5 + bitmap_x]) begin
                        pixel_color <= RED;  // Color of the point
                    end else begin
                        pixel_color <= BLACK;
                    end
                end
                else if (x >= point_position_speed - 2 && x <= point_position_speed + 2 && y >= SCALE_Y_SPEED - 2 && y <= SCALE_Y_SPEED + 2) begin
                    // Extract the bitmap pixel data
                    bitmap_x = x - (point_position_speed - 2);
                    bitmap_y = y - (SCALE_Y_SPEED - 2);
                    if (point_bitmap[bitmap_y * 5 + bitmap_x]) begin
                        pixel_color <= RED;  // Color of the point
                    end
                end
                else if (y == SCALE_Y_TIME && x >= SCALE_X_START && x <= (SCALE_X_START + SCALE_LENGTH)) begin
                    pixel_color <= WHITE;  // Color of the scale
                end
                else if (y == SCALE_Y_SPEED && x >= SCALE_X_START && x <= (SCALE_X_START + SCALE_LENGTH)) begin
                    pixel_color <= WHITE;  // Color of the scale
                end
                else begin
                    // Outside the image area, set to background color
                    pixel_color <= selected_bram_data;
                end
            end
            STATE_FINAL: begin
                if (winner) begin
                    pixel_color <= hider_win;
                end else begin
                    pixel_color <= seeker_win;
                end
            end
        endcase
    end
    // Button edge detection
    reg btnU_prev, btnD_prev, btnC_prev, btnL_prev, btnR_prev;
    
    //UART Receiver parameters 
    localparam CMD_GAME_START = 8'h20;
    localparam CMD_GAME_READY = 8'h21;
    
    // Menu and game state logic
    always @(posedge clk or posedge reset) begin
        btnU_prev <= btnU_db;
        btnD_prev <= btnD_db;
        btnC_prev <= btnC_db;
        btnL_prev <= btnL_db;
        btnR_prev <= btnR_db;
        
        if (reset) begin
            current_state <= STATE_MENU;
        end else begin
            case (current_state)
                STATE_MENU: begin
                    game_started <= 0;
                    if (btnU_db && !btnU_prev && menu_selection > 0) begin
                        menu_selection <= menu_selection - 1;
                    end
                    else if (btnD_db && !btnD_prev && menu_selection < MENU_OPTION_COUNT - 1) begin
                        menu_selection <= menu_selection + 1;
                    end
                    else if (btnC_db && !btnC_prev) begin
                        case (menu_selection)
                            0: begin  // Start Game
                                current_state <= STATE_GAME;
                            end
                            1: begin
                                current_state <= STATE_SETTINGS;
                            end
                        endcase
                    end
                    end
                
                STATE_SETTINGS: begin
                    if (btnU_db && !btnU_prev && settings_selection > 0) begin
                        settings_selection <= settings_selection - 1;
                    end
                    else if (btnD_db && !btnD_prev && settings_selection < SETTINGS_OPTION_COUNT - 1) begin
                        settings_selection <= settings_selection + 1;
                    end
                    case (settings_selection)
                        0: begin
                            //time settings
                            if (btnL_db && !btnL_prev && time_setting > TIME_MIN) begin
                                time_setting <= time_setting - 1;
                            end else if (btnR_db && !btnR_prev && time_setting < TIME_MAX) begin
                                time_setting <= time_setting + 1;
                            end
                        end
                        1: begin
                            // speed settings
                            if (btnL_db && !btnL_prev && speed_setting > SPEED_MIN) begin
                                speed_setting <= speed_setting - 1;
                            end else if (btnR_db && !btnR_prev && speed_setting < SPEED_MAX) begin
                                speed_setting <= speed_setting + 1;
                            end
                        end
                        2: begin
                            // return to menu page
                            if (btnC_db && !btnC_prev) begin
                                current_state <= STATE_MENU;
                            end 
                        end
                    endcase
                end
        
                STATE_GAME: begin
                    // Handle game state updates
                    game_started <= 1;
                    if (game_done) begin
                        current_state <= STATE_FINAL;
                    end
                    //game_pause <= 0;
                end
                
                STATE_FINAL: begin
                    game_started <= 0;
                    if (btnC_db && !btnC_prev) begin
                        current_state <= STATE_MENU;
                    end  
                end
            endcase
        end
    end
endmodule
