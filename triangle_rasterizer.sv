module triangle_rasterizer (
    input  logic        clk,
    input  logic        rst,

    // Clear the depth buffer
    input  logic        clear_start,
    output logic        clear_busy,
    output logic        clear_done,

    // Begin drawing one triangle
    input  logic        triangle_start,

    input  logic [7:0]  x0,
    input  logic [6:0]  y0,
    input  logic [7:0]  x1,
    input  logic [6:0]  y1,
    input  logic [7:0]  x2,
    input  logic [6:0]  y2,

    input  logic [15:0] triangle_depth,
    input  logic [11:0] triangle_color,

    output logic        triangle_busy,
    output logic        triangle_done,

    // Framebuffer read port for the VGA controller
    input  logic [7:0]  display_x,
    input  logic [6:0]  display_y,
    output logic [11:0] display_color
);

/*----------------------------------------------------------
 * Saved triangle command
 *----------------------------------------------------------*/

logic [7:0]  x0_reg;
logic [6:0]  y0_reg;
logic [7:0]  x1_reg;
logic [6:0]  y1_reg;
logic [7:0]  x2_reg;
logic [6:0]  y2_reg;

logic [15:0] triangle_depth_reg;
logic [11:0] triangle_color_reg;

logic scanner_start;

/*----------------------------------------------------------
 * Bounding-box signals
 *----------------------------------------------------------*/

logic [7:0] min_x;
logic [7:0] max_x;
logic [6:0] min_y;
logic [6:0] max_y;

/*----------------------------------------------------------
 * Scanner signals
 *----------------------------------------------------------*/

logic [7:0] scanner_pixel_x;
logic [6:0] scanner_pixel_y;
logic       scanner_pixel_valid;
logic       scanner_busy;
logic       scanner_done;

/*----------------------------------------------------------
 * Triangle inside-test signal
 *----------------------------------------------------------*/

logic pixel_inside;

/*----------------------------------------------------------
 * Depth-test signals
 *----------------------------------------------------------*/

logic [7:0]  depth_read_x;
logic [6:0]  depth_read_y;
logic [15:0] stored_depth;

logic        pixel_write_en;
logic [7:0]  pixel_write_x;
logic [6:0]  pixel_write_y;
logic [15:0] pixel_write_depth;
logic [11:0] pixel_write_color;

/*----------------------------------------------------------
 * Depth-buffer clearing signals
 *----------------------------------------------------------*/

logic        clear_write_en;
logic [7:0]  clear_x;
logic [6:0]  clear_y;
logic [15:0] clear_depth;

/*----------------------------------------------------------
 * Selected depth-buffer write port
 *----------------------------------------------------------*/

logic        depth_write_en;
logic [7:0]  depth_write_x;
logic [6:0]  depth_write_y;
logic [15:0] depth_write_value;

/*----------------------------------------------------------
 * Pipeline completion signals
 *----------------------------------------------------------*/


/*----------------------------------------------------------
 * Accept and save a triangle command
 *----------------------------------------------------------*/

always_ff @(posedge clk) begin
    if (rst) begin
        x0_reg             <= 0;
        y0_reg             <= 0;
        x1_reg             <= 0;
        y1_reg             <= 0;
        x2_reg             <= 0;
        y2_reg             <= 0;
        triangle_depth_reg <= 0;
        triangle_color_reg <= 0;
        scanner_start      <= 0;
    end else begin
        // scanner_start is normally a one-clock pulse
        scanner_start <= 0;

        if (triangle_start &&
            !triangle_busy &&
            !clear_busy) begin

            x0_reg             <= x0;
            y0_reg             <= y0;
            x1_reg             <= x1;
            y1_reg             <= y1;
            x2_reg             <= x2;
            y2_reg             <= y2;
            triangle_depth_reg <= triangle_depth;
            triangle_color_reg <= triangle_color;

            scanner_start <= 1;
        end
    end
end

/*----------------------------------------------------------
 * Bounding-box generator
 *----------------------------------------------------------*/

triangle_bounding_box bounding_box_inst (
    .x0    (x0_reg),
    .y0    (y0_reg),
    .x1    (x1_reg),
    .y1    (y1_reg),
    .x2    (x2_reg),
    .y2    (y2_reg),

    .min_x (min_x),
    .max_x (max_x),
    .min_y (min_y),
    .max_y (max_y)
);

/*----------------------------------------------------------
 * Bounding-box scanner
 *----------------------------------------------------------*/

bounding_box_scanner scanner_inst (
    .clk         (clk),
    .rst         (rst),
    .start       (scanner_start),

    .min_x       (min_x),
    .max_x       (max_x),
    .min_y       (min_y),
    .max_y       (max_y),

    .pixel_x     (scanner_pixel_x),
    .pixel_y     (scanner_pixel_y),
    .pixel_valid (scanner_pixel_valid),
    .busy        (scanner_busy),
    .done        (scanner_done)
);

/*----------------------------------------------------------
 * Triangle inside test
 *----------------------------------------------------------*/

triangle_inside_test inside_test_inst (
    .x0           (x0_reg),
    .y0           (y0_reg),
    .x1           (x1_reg),
    .y1           (y1_reg),
    .x2           (x2_reg),
    .y2           (y2_reg),

    .pixel_x      (scanner_pixel_x),
    .pixel_y      (scanner_pixel_y),
    .pixel_valid  (scanner_pixel_valid),

    .pixel_inside (pixel_inside)
);

/*----------------------------------------------------------
 * Depth test
 *----------------------------------------------------------*/

depth_test depth_test_inst (
    .clk          (clk),
    .rst          (rst),

    .pixel_inside (pixel_inside),
    .pixel_x      (scanner_pixel_x),
    .pixel_y      (scanner_pixel_y),
    .new_depth    (triangle_depth_reg),
    .new_color    (triangle_color_reg),

    .stored_depth (stored_depth),

    .depth_read_x (depth_read_x),
    .depth_read_y (depth_read_y),

    .write_en     (pixel_write_en),
    .write_x      (pixel_write_x),
    .write_y      (pixel_write_y),
    .write_depth  (pixel_write_depth),
    .write_color  (pixel_write_color)
);

/*----------------------------------------------------------
 * Depth-buffer clear controller
 *----------------------------------------------------------*/

depth_buffer_clear clear_inst (
    .clk            (clk),
    .rst            (rst),
    .start          (clear_start),

    .clear_busy     (clear_busy),
    .clear_done     (clear_done),

    .clear_write_en (clear_write_en),
    .clear_x        (clear_x),
    .clear_y        (clear_y),
    .clear_depth    (clear_depth)
);

/*----------------------------------------------------------
 * Select the owner of the depth-buffer write port
 *----------------------------------------------------------*/

always_comb begin
    if (clear_busy) begin
        depth_write_en    = clear_write_en;
        depth_write_x     = clear_x;
        depth_write_y     = clear_y;
        depth_write_value = clear_depth;
    end else begin
        depth_write_en    = pixel_write_en;
        depth_write_x     = pixel_write_x;
        depth_write_y     = pixel_write_y;
        depth_write_value = pixel_write_depth;
    end
end

/*----------------------------------------------------------
 * Depth buffer
 *----------------------------------------------------------*/

depth_buffer depth_buffer_inst (
    .clk         (clk),

    .write_en    (depth_write_en),
    .write_x     (depth_write_x),
    .write_y     (depth_write_y),
    .write_depth (depth_write_value),

    .read_x      (depth_read_x),
    .read_y      (depth_read_y),
    .read_depth  (stored_depth)
);

/*----------------------------------------------------------
 * Framebuffer
 *
 * Only pixels that pass the depth test are written here.
 * Clearing the depth buffer does not clear the framebuffer.
 *----------------------------------------------------------*/

framebuffer framebuffer_inst (
    .clk         (clk),

    .write_en    (pixel_write_en && !clear_busy),
    .write_x     (pixel_write_x),
    .write_y     (pixel_write_y),
    .write_color (pixel_write_color),

    .read_x      (display_x),
    .read_y      (display_y),
    .read_color  (display_color)
);

/*----------------------------------------------------------
 * Busy and done timing
 *
 * The scanner finishes before the final depth-test result
 * completes, so scanner_done is delayed.
 *----------------------------------------------------------*/

logic scanner_done_delay1;
logic scanner_done_delay2;

always_ff @(posedge clk) begin
    if (rst) begin
        scanner_done_delay1 <= 0;
        scanner_done_delay2 <= 0;
    end else begin
        scanner_done_delay1 <= scanner_done;
        scanner_done_delay2 <= scanner_done_delay1;
    end
end

assign triangle_busy =
    scanner_start ||
    scanner_busy  ||
    scanner_done  ||
    scanner_done_delay2;

assign triangle_done = scanner_done_delay2;

endmodule