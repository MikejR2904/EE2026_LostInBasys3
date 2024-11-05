module top_level (
    input basys_clock,
    input [15:0] SW,       // For SW[15]
    input [4:0] PB,        // For push buttons
    output [7:0] JC,       // For OLED
    output reg [15:0] led  // For debugging
);
    // Declarations
    // State Machine
    reg [2:0] current_state, next_state;
    parameter IDLE = 3'b000, INIT_MAZE = 3'b001, PLACE_COLLECTIBLES = 3'b010, PLACE_PLAYER = 3'b011, DISPLAY_MAZE = 3'b100;

    // Clocks
    wire clk6p25m;

    // Debounced and Edge Signals
    wire [4:0] pb_debounced;
    wire [4:0] pb_edge;

    // Effective Signals Based on SW[15]
    wire reset_edge_effective, gen_edge_effective, next_level_edge_effective;
    wire up_edge_effective, down_edge_effective, left_edge_effective, right_edge_effective, stop_edge_effective;

    // Level Selection
    reg [2:0] level_select;

    // Maze Generator Outputs
    wire [7:0] bram_addr_gen;
    wire [8:0] bram_data_in_gen;
    wire we_gen, gen_done;

    // Collectibles Placement Outputs
    wire [7:0] bram_addr_out;
    wire [8:0] collectible_data_in;
    wire we_collectible, placement_done;
    wire [15:0] led_data;
    reg collectibles_reset_reg;
    wire collectibles_reset;

    // Player Position and Placement
    wire [3:0] player_x;
    wire [3:0] player_y;
    wire player_placement_done;
    wire [3:0] initial_player_x, initial_player_y;
    wire [7:0] player_spawner_bram_addr;
    wire [2:0] chunk_x;
    wire [2:0] chunk_y;
    wire [1:0] player_direction;
    wire [1:0] bot_direction;
    
    // Bot position
    wire [3:0] seeker_x;
    wire [3:0] seeker_y;

    // Player Movement Variables
    wire [7:0] player_movement_bram_addr;
    wire [8:0] player_bram_data;
    wire we_player;
    wire [8:0] bram_din_player;
    wire [7:0] bram_addr_player;

    // Control Signals
    wire collectibles_en;
    wire random_index_en;
    wire [7:0] random_generated_index;
    wire [1:0] random_collectible_type;

    // BRAM Control Signals
    wire maze_gen_active, collectibles_active, player_read_active, player_placement_active, player_write_active;
    wire bram_en_a, bram_we_a;
    wire [7:0] bram_addr_a;
    wire [8:0] bram_din_a;
    wire [8:0] bram_dout_a, bram_dout_b;
    wire [7:0] bram_addr_disp;

    // Display Signals
    wire [12:0] pixel_index;
    reg [15:0] oled_data;
    wire [15:0] oled_data_maze;
    wire [15:0] oled_data_timer;

    // Movement Clock
    parameter MOVEMENT_CLOCK_DIV = 24_999_999; // Slower movement clock (~2 Hz)
    reg [24:0] movement_clock_counter;

    // 1-second Clock for Timer
    reg [26:0] one_sec_counter;
    wire one_sec_tick;

    // Timer
    reg [15:0] time_left;

    // Parameters for Timer Display Area
    parameter BOX_X = 1;
    parameter BOX_Y = 12;
    parameter BOX_WIDTH = 29;
    parameter BOX_HEIGHT = 13;

    // Pixel Coordinates
    wire [6:0] x = pixel_index % 96;
    wire [6:0] y = pixel_index / 96;
    
    // Menu states
    wire game_started;
    wire game_done;
    wire winner;
    wire [15:0] menu_oled_data;
    wire [7:0] time_setting;
    wire [7:0] speed_setting;

    // 1-second Clock Divider for Timer
    always @(posedge basys_clock or posedge reset_edge_effective) begin
        if (reset_edge_effective) begin
            one_sec_counter <= 0;
        end else begin
            if (one_sec_counter == 99_999_999) begin
                one_sec_counter <= 0;
            end else begin
                one_sec_counter <= one_sec_counter + 1;
            end
        end
    end

    assign one_sec_tick = (one_sec_counter == 99_999_999);
    reg game_done_time, winner_time;
    localparam TIMELIMIT1 = 60;
    localparam TIMELIMIT2 = 120;
    localparam TIMELIMIT3 = 180;
    localparam TIMELIMIT4 = 240;
    wire [7:0] TIMELIMIT; 
    assign TIMELIMIT = time_setting == 1 ? TIMELIMIT1 :
                       time_setting == 2 ? TIMELIMIT2 :
                       time_setting == 3 ? TIMELIMIT3 :
                       time_setting == 4 ? TIMELIMIT4 :
                       TIMELIMIT3;
    
    
    // Timer Logic
    always @(posedge basys_clock or posedge reset_edge_effective) begin
        if (reset_edge_effective) begin
            time_left <= TIMELIMIT; // Initialize to 3 minutes
            game_done_time <= 0;
            winner_time <= 0;
        end else if (one_sec_tick && current_state == DISPLAY_MAZE) begin
            if (time_left > 0) begin
                time_left <= time_left - 1;
            end else begin
                game_done_time <= 1;
                winner_time <= 1;
            end
        end else if (current_state != DISPLAY_MAZE) begin
            // Reset timer when not in DISPLAY_MAZE state
            time_left <= TIMELIMIT;
        end
    end
    


    // Instantiations
    // Clock Divider for OLED (6.25 MHz)
    clk_divider clk6p25MHz (
        .clk_in(basys_clock),
        .m(7),
        .clk_out(clk6p25m)
    );

    // Debounce and Edge Detectors
    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : debounce_gen
            debounce debounce_inst (
                .clk(basys_clock),
                .btn_in(PB[i]),
                .btn_out(pb_debounced[i])
            );
            rising_edge_detector edge_inst (
                .clk(basys_clock),
                .signal_in(pb_debounced[i]),
                .signal_out(pb_edge[i])
            );
        end
    endgenerate

    // Define Buttons Based on SW[15]
    wire reset_debounced = (~SW[15]) ? pb_debounced[0] : 1'b0;
    wire gen_debounced = (~SW[15]) ? pb_debounced[1] : 1'b0;
    wire next_level_debounced = (~SW[15]) ? pb_debounced[4] : 1'b0;

    wire up_debounced = (SW[15]) ? pb_debounced[1] : 1'b0;
    wire left_debounced = (SW[15]) ? pb_debounced[2] : 1'b0;
    wire right_debounced = (SW[15]) ? pb_debounced[3] : 1'b0;
    wire down_debounced = (SW[15]) ? pb_debounced[4] : 1'b0;

    // Effective Edge Signals
    wire reset_edge = SW[0];
    wire gen_edge = pb_edge[1];
    wire next_level_edge = pb_edge[4];
    wire up_edge = pb_edge[1];
    wire left_edge = pb_edge[2];
    wire right_edge = pb_edge[3];
    wire down_edge = pb_edge[4];

    assign reset_edge_effective = (~SW[15]) ? reset_edge : 1'b0;
    assign gen_edge_effective = (~SW[15]) ? gen_edge : 1'b0;
    assign next_level_edge_effective = (~SW[15]) ? next_level_edge : 1'b0;

    assign up_edge_effective = (SW[15]) ? up_edge : 1'b0;
    assign down_edge_effective = (SW[15]) ? down_edge : 1'b0;
    assign left_edge_effective = (SW[15]) ? left_edge : 1'b0;
    assign right_edge_effective = (SW[15]) ? right_edge : 1'b0;
    assign stop_edge_effective = (SW[15]) ? pb_edge[0] : 1'b0; // Center button for stopping movement

    // Level Selection Logic
    always @(posedge basys_clock or posedge reset_edge_effective) begin
        if (reset_edge_effective) begin
            level_select <= 1;
        end else if (next_level_edge_effective) begin
            if (level_select < 6)
                level_select <= level_select + 1;
            else
                level_select <= 1;
        end
    end

    // Maze Generator
    maze_generator maze_gen (
        .clk(basys_clock),
        .reset(reset_edge_effective),
        .gen(gen_edge_effective),
        .level_select(level_select),
        .bram_addr(bram_addr_gen),
        .bram_data_in(bram_data_in_gen),
        .we(we_gen),
        .done(gen_done)
    );

    // Random Index Generator Enable Signal
    assign collectibles_en = (current_state == PLACE_COLLECTIBLES);
    assign random_index_en = collectibles_en | (current_state == PLACE_PLAYER);

    // Random Placement Index Generator
    random_placement_index_generator #(.SIZE(256), .LFSR_BITS(8)) placement_generator (
        .clk(basys_clock),
        .reset(reset_edge_effective),
        .en(random_index_en),
        .random_index(random_generated_index)
    );

    // Random Collectible Type Generator
    random_collectible_type_generator collectible_type_generator (
        .clk(basys_clock),
        .reset(collectibles_reset),
        .en(collectibles_en),
        .random_type(random_collectible_type)
    );

    // Collectibles Random Placement
    collectibles_random_placement #(.MIN_DISTANCE(3)) collectible_placer (
        .clk(basys_clock),
        .reset(collectibles_reset),
        .en(collectibles_en),
        .x_seeker_init(player_x),
        .y_seeker_init(player_y),
        .x_hider_init(13),
        .y_hider_init(13),
        .random_index(random_generated_index),
        .random_collectible_type(random_collectible_type),
        .bram_mem_in(bram_dout_a),
        .bram_mem_out(collectible_data_in),
        .found_index(),
        .finished_placement(placement_done),
        .led(led_data),
        .we_collectible(we_collectible),
        .bram_addr_out(bram_addr_out)
    );

    // Maze BRAM
    maze_bram maze_memory (
        .clk_a(basys_clock),
        .en_a(bram_en_a),
        .we_a(bram_we_a),
        .addr_a(bram_addr_a),
        .din_a(bram_din_a),
        .dout_a(bram_dout_a),
        .clk_b(clk6p25m),
        .en_b(1),
        .we_b(0),
        .addr_b(bram_addr_disp),
        .din_b(9'b0),
        .dout_b(bram_dout_b)
    );

    // Maze Display
    maze_display display_inst (
        .clk(clk6p25m),
        .reset(reset_edge_effective),
        .en(player_read_active),
        .pixel_index(pixel_index),
        .bram_addr(bram_addr_disp),
        .bram_data_out(bram_dout_b),
        .playerX(player_x),
        .playerY(player_y),
        .botX(seeker_x),
        .botY(seeker_y),
        .chunkX(chunk_x),
        .chunkY(chunk_y),
        .dir(player_direction),
        .pixel_data(oled_data_maze)
    );
    // Timer Display
    timer_display timer_disp (
        .clk(clk6p25m),
        .reset(reset_edge_effective),
        .en(1'b1),
        .time_left(time_left),
        .pixel_index(pixel_index),
        .oled_data(oled_data_timer)
    );
    
    wire [10:0] energy;
    wire [15:0] oled_data_energy_bar;
    localparam BAR_WIDTH = 10; localparam BAR_DISPLAY_HEIGHT = 60; localparam NUM_BARS = 10 ; 
    localparam BAR_HEIGHT = 2; localparam GAP_HEIGHT = 1;
    localparam BAR_WITH_GAP = BAR_HEIGHT + GAP_HEIGHT;
    
    energy_bar_display energy_disp (
        .clk(clk6p25m),
        .reset(0), 
        .energy(energy), 
        .pixel_index(pixel_index), 
        .oled_data(oled_data_energy_bar)
        );

    // OLED Display
    Oled_Display oled_inst (
        .clk(clk6p25m),
        .reset(reset_edge_effective),
        .frame_begin(),
        .sending_pixels(),
        .sample_pixel(),
        .pixel_index(pixel_index),
        .pixel_data(oled_data),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
    
    wire [15:0] oled_data_compass;
    
    compass_display compass(
        .clk(basys_clock), 
        .reset(reset_edge_effective), 
        .en(current_state == DISPLAY_MAZE), 
        .x_seeker(player_x), 
        .y_seeker(player_y), 
        .x_hider(seeker_x), 
        .y_hider(seeker_y), 
        .pixel_index(pixel_index), 
        .oled_data(oled_data_compass)
        );
    

    menu_display menu_display_inst(
        .clk(basys_clock),
        .reset(reset_edge_effective),
        .btnU(PB[1]),
        .btnC(PB[0]),
        .btnL(PB[2]),
        .btnR(PB[3]),
        .btnD(PB[4]),
        .game_started(game_started),
        .game_done(game_done),
        .winner(winner),
        .time_setting(time_setting),
        .speed_setting(speed_setting),
        .pixel_index(pixel_index),
        .pixel_color(menu_oled_data)
    );    
    

    reg [12:0] center_x = 64;
    reg [12:0] center_y = 32;
    // Combine Maze and Timer Display Data
    always @(*) begin
        if (game_started) begin 
            if ((x >= BOX_X) && (x < BOX_X + BOX_WIDTH) && (y >= BOX_Y) && (y < BOX_Y + BOX_HEIGHT)) begin
                oled_data = oled_data_timer;
            end else if (x >= 2 && x < BAR_WIDTH && y >= BAR_DISPLAY_HEIGHT - (NUM_BARS * BAR_WITH_GAP) && y < BAR_DISPLAY_HEIGHT) begin
                oled_data = oled_data_energy_bar;
            end else begin
                oled_data = oled_data_maze | oled_data_compass;
            end
        end else begin
            oled_data = menu_oled_data;
        end
    end

    // Always Blocks and Logic
    // State Machine
    always @(posedge basys_clock or posedge reset_edge_effective) begin
        if (reset_edge_effective) begin
            current_state <= IDLE;
            collectibles_reset_reg <= 0;
        end else begin
            current_state <= next_state;
            if (next_state == PLACE_COLLECTIBLES && current_state != PLACE_COLLECTIBLES) begin
                collectibles_reset_reg <= 1; // Generate a one-cycle reset pulse
            end else begin
                collectibles_reset_reg <= 0;
            end
        end
    end

    assign collectibles_reset = collectibles_reset_reg;
    


    // Next State Logic
    always @(*) begin
        if (game_started) begin
            next_state = current_state;
            case (current_state)
                IDLE: begin
                    if (gen_edge_effective) begin
                        next_state = INIT_MAZE;
                    end
                end
                INIT_MAZE: begin
                    if (gen_done) begin
                        next_state = PLACE_COLLECTIBLES;
                    end
                end
                PLACE_COLLECTIBLES: begin
                    if (placement_done) begin
                        next_state = PLACE_PLAYER;
                    end
                end
                PLACE_PLAYER: begin
                    if (player_placement_done) begin
                        next_state = DISPLAY_MAZE;
                    end
                end
                DISPLAY_MAZE: begin
                    if (gen_edge_effective) begin
                        next_state = INIT_MAZE;
                    end else if (reset_edge_effective) begin
                        next_state = IDLE;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end

    // Player Spawner
    player_spawner spawner (
        .clk(basys_clock),
        .reset(reset_edge_effective),
        .en(current_state == PLACE_PLAYER),
        .bram_dout(bram_dout_a),
        .random_index(random_generated_index),
        .bram_addr(player_spawner_bram_addr),
        .player_x(initial_player_x),
        .player_y(initial_player_y),
        .player_placement_done(player_placement_done)
    );


    player_movement movement (
        .sysclk(basys_clock),
        .reset(reset_edge_effective),
        .en(current_state == DISPLAY_MAZE),
        .initial_player_x(initial_player_x),
        .initial_player_y(initial_player_y),
        .bram_dout(bram_dout_a),
        .PB(PB),
        .playerX(player_x),
        .playerY(player_y),
        .chunkX(chunk_x),
        .chunkY(chunk_y),
        .dir(player_direction),
        .bram_addr(player_movement_bram_addr),
        .we_player(we_player),
        .bram_din_player(bram_din_player),
        .bram_addr_player(bram_addr_player),
        .energy(energy)
    );
    wire game_done_bot, winner_bot;
    
    seeker_bot bot(
        .clk(basys_clock),
        .rst(reset_edge_effective),
        .hider_x(player_x),      // Hider's x position
        .hider_y(player_y),      // Hider's y position
        .level_select(level_select),
        .seeker_x(seeker_x),     // Seeker's current x position
        .seeker_y(seeker_y),     // Seeker's current y position
        .dir(bot_direction),
        .done(game_done_bot),
        .winner(winner_bot)
    );
    

    // BRAM Control Signals
    assign maze_gen_active = (current_state == INIT_MAZE);
    assign collectibles_active = (current_state == PLACE_COLLECTIBLES);
    assign player_placement_active = (current_state == PLACE_PLAYER);
    assign player_read_active = (current_state == DISPLAY_MAZE);
    assign player_write_active = (current_state == DISPLAY_MAZE) & we_player;

    assign bram_en_a = maze_gen_active | collectibles_active | player_placement_active | player_read_active | player_write_active;
    assign bram_we_a = maze_gen_active ? we_gen :
                       collectibles_active ? we_collectible :
                       player_write_active ? we_player : 1'b0;

    assign bram_addr_a = maze_gen_active ? bram_addr_gen :
                         collectibles_active ? bram_addr_out :
                         player_write_active ? bram_addr_player :
                         player_placement_active ? player_spawner_bram_addr :
                         player_read_active ? player_movement_bram_addr : 8'b0;

    assign bram_din_a = maze_gen_active ? bram_data_in_gen :
                        collectibles_active ? collectible_data_in :
                        player_write_active ? bram_din_player : 9'b0;

    // BRAM output data for player movement
    assign player_bram_data = bram_dout_a;

    assign winner = winner_time | winner_bot;
    assign game_done = game_done_time | game_done_bot;
    
    // LED Outputs for Debugging
    always @(posedge basys_clock) begin
        led[15] <= SW[15];          // Indicate SW[15] status
        led[14:11] <= player_x;     // Player X position
        led[10:7] <= player_y;      // Player Y position
        led[6:0] <= 7'b0;
    end

endmodule
