module vga_timing (
    input  logic       pixel_clk,
    input  logic       rst,

    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y,
    output logic       active_video,
    output logic       hsync,
    output logic       vsync
);

logic [9:0] h_counter;
logic [9:0] v_counter;

// Horizontal and vertical counters
always_ff @(posedge pixel_clk) begin
    if (rst) begin
        h_counter <= 10'd0;
        v_counter <= 10'd0;
    end else begin
        if (h_counter == 10'd799) begin
            h_counter <= 10'd0;

            if (v_counter == 10'd524) begin
                v_counter <= 10'd0;
            end else begin
                v_counter <= v_counter + 1'b1;
            end
        end else begin
            h_counter <= h_counter + 1'b1;
        end
    end
end

// Current VGA timing position
assign pixel_x = h_counter;
assign pixel_y = v_counter;

// The visible portion is 640 × 480
assign active_video =
    (h_counter < 10'd640) &&
    (v_counter < 10'd480);

// Horizontal sync is active-low from 656 through 751
assign hsync = ~(
    (h_counter >= 10'd656) &&
    (h_counter <  10'd752)
);

// Vertical sync is active-low on lines 490 and 491
assign vsync = ~(
    (v_counter >= 10'd490) &&
    (v_counter <  10'd492)
);

endmodule