module top_module (
    input  logic       clk_100mhz,
    input  logic       reset_btn,

    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue,
    output logic       vga_hsync,
    output logic       vga_vsync
);

/*----------------------------------------------------------
 * Clock-divider signals
 *----------------------------------------------------------*/

logic [1:0] clock_counter;
logic       clk_25mhz;

/*----------------------------------------------------------
 * Rasterizer control
 *----------------------------------------------------------*/

logic clear_start;
logic clear_busy;
logic clear_done;

logic triangle_start;
logic triangle_busy;
logic triangle_done;

/*----------------------------------------------------------
 * Triangle command
 *----------------------------------------------------------*/

logic [7:0] x0;
logic [6:0] y0;

logic [7:0] x1;
logic [6:0] y1;

logic [7:0] x2;
logic [6:0] y2;

logic [15:0] triangle_depth;
logic [11:0] triangle_color;

/*----------------------------------------------------------
 * Framebuffer display port
 *----------------------------------------------------------*/

logic [7:0]  display_x;
logic [6:0]  display_y;
logic [11:0] display_color;

/*----------------------------------------------------------
 * VGA timing signals
 *----------------------------------------------------------*/

logic [9:0] vga_x;
logic [9:0] vga_y;
logic       video_active;

/*----------------------------------------------------------
 * Scene-control FSM
 *----------------------------------------------------------*/

typedef enum logic [3:0] {
    RESET_STATE,
    CLEAR_START_STATE,
    CLEAR_WAIT_STATE,
    TRIANGLE_1_START_STATE,
    TRIANGLE_1_WAIT_STATE,
    TRIANGLE_2_START_STATE,
    TRIANGLE_2_WAIT_STATE,
    DISPLAY_STATE
} state_t;

state_t current_state;
state_t next_state;

/*----------------------------------------------------------
 * 100 MHz to 25 MHz clock divider
 *----------------------------------------------------------*/

always_ff @(posedge clk_100mhz) begin
    if (reset_btn) begin
        clock_counter <= 2'b00;
        clk_25mhz     <= 1'b0;
    end else begin
        if (clock_counter == 2'b01) begin
            clock_counter <= 2'b00;
            clk_25mhz     <= ~clk_25mhz;
        end else begin
            clock_counter <= clock_counter + 1'b1;
        end
    end
end

/*----------------------------------------------------------
 * FSM state register
 *----------------------------------------------------------*/

always_ff @(posedge clk_100mhz) begin
    if (reset_btn) begin
        current_state <= RESET_STATE;
    end else begin
        current_state <= next_state;
    end
end

/*----------------------------------------------------------
 * FSM next-state logic
 *----------------------------------------------------------*/

always_comb begin
    next_state = current_state;

    case (current_state)

        RESET_STATE: begin
            next_state = CLEAR_START_STATE;
        end

        CLEAR_START_STATE: begin
            next_state = CLEAR_WAIT_STATE;
        end

        CLEAR_WAIT_STATE: begin
            if (clear_done) begin
                next_state = TRIANGLE_1_START_STATE;
            end
        end

        TRIANGLE_1_START_STATE: begin
            next_state = TRIANGLE_1_WAIT_STATE;
        end

        TRIANGLE_1_WAIT_STATE: begin
            if (triangle_done) begin
                next_state = TRIANGLE_2_START_STATE;
            end
        end

        TRIANGLE_2_START_STATE: begin
            next_state = TRIANGLE_2_WAIT_STATE;
        end

        TRIANGLE_2_WAIT_STATE: begin
            if (triangle_done) begin
                next_state = DISPLAY_STATE;
            end
        end

        DISPLAY_STATE: begin
            next_state = DISPLAY_STATE;
        end

        default: begin
            next_state = RESET_STATE;
        end

    endcase
end

/*----------------------------------------------------------
 * FSM output logic
 *----------------------------------------------------------*/

always_comb begin
    clear_start    = 1'b0;
    triangle_start = 1'b0;

    x0 = 8'd0;
    y0 = 7'd0;
    x1 = 8'd0;
    y1 = 7'd0;
    x2 = 8'd0;
    y2 = 7'd0;

    triangle_depth = 16'd0;
    triangle_color = 12'h000;

    case (current_state)

        CLEAR_START_STATE: begin
            clear_start = 1'b1;
        end

        TRIANGLE_1_START_STATE: begin
            triangle_start = 1'b1;

            x0 = 8'd85;
            y0 = 7'd42;

            x1 = 8'd25;
            y1 = 7'd9;

            x2 = 8'd54;
            y2 = 7'd4;

            triangle_depth = 16'h5552;
            triangle_color = 12'hAAA;
        end

        TRIANGLE_2_START_STATE: begin
            triangle_start = 1'b1;

            // Same position for complete overlap
            x0 = 8'd85;
            y0 = 7'd42;

            x1 = 8'd25;
            y1 = 7'd9;

            x2 = 8'd54;
            y2 = 7'd4;

            // Triangle 2 is closer
            triangle_depth = 16'h3555;
            triangle_color = 12'h2AA;
        end

        default: begin
            // Keep the default values
        end

    endcase
end

/*----------------------------------------------------------
 * Convert 640x480 coordinates to 160x120 coordinates
 *
 * Dividing both coordinates by four makes every framebuffer
 * pixel appear as a 4x4 block on the VGA display.
 *----------------------------------------------------------*/

always_comb begin
    if (video_active) begin
        display_x = vga_x[9:2];
        display_y = vga_y[8:2];
    end else begin
        display_x = 8'd0;
        display_y = 7'd0;
    end
end

/*----------------------------------------------------------
 * Drive VGA colors
 *----------------------------------------------------------*/

always_comb begin
    if (video_active) begin
        vga_red   = display_color[11:8];
        vga_green = display_color[7:4];
        vga_blue  = display_color[3:0];
    end else begin
        vga_red   = 4'h0;
        vga_green = 4'h0;
        vga_blue  = 4'h0;
    end
end

/*----------------------------------------------------------
 * Triangle rasterizer
 *----------------------------------------------------------*/

triangle_rasterizer rasterizer_inst (
    .clk            (clk_100mhz),
    .rst            (reset_btn),

    .clear_start    (clear_start),
    .clear_busy     (clear_busy),
    .clear_done     (clear_done),

    .triangle_start (triangle_start),

    .x0             (x0),
    .y0             (y0),
    .x1             (x1),
    .y1             (y1),
    .x2             (x2),
    .y2             (y2),

    .triangle_depth (triangle_depth),
    .triangle_color (triangle_color),

    .triangle_busy  (triangle_busy),
    .triangle_done  (triangle_done),

    .display_x      (display_x),
    .display_y      (display_y),
    .display_color  (display_color)
);

/*----------------------------------------------------------
 * VGA timing generator
 *----------------------------------------------------------*/

vga_timing vga_timing_inst (
    .clk          (clk_25mhz),
    .rst          (reset_btn),

    .hsync        (vga_hsync),
    .vsync        (vga_vsync),

    .pixel_x      (vga_x),
    .pixel_y      (vga_y),
    .video_active (video_active)
);

endmodule