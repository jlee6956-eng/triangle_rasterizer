module depth_test (
    input  logic        clk,
    input  logic        rst,

    input  logic        pixel_inside,
    input  logic [7:0]  pixel_x,
    input  logic [6:0]  pixel_y,
    input  logic [15:0] new_depth,
    input  logic [11:0] new_color,

    input  logic [15:0] stored_depth,

    output logic [7:0]  depth_read_x,
    output logic [6:0]  depth_read_y,

    output logic        write_en,
    output logic [7:0]  write_x,
    output logic [6:0]  write_y,
    output logic [15:0] write_depth,
    output logic [11:0] write_color
);

logic        saved_valid;
logic [7:0]  saved_x;
logic [6:0]  saved_y;
logic [15:0] saved_depth;
logic [11:0] saved_color;

// Tell the depth buffer which coordinate to read.
assign depth_read_x = pixel_x;
assign depth_read_y = pixel_y;

always_ff @(posedge clk) begin
    if (rst) begin
        saved_valid <= 0;
        saved_x     <= 0;
        saved_y     <= 0;
        saved_depth <= 0;
        saved_color <= 0;

        write_en    <= 0;
        write_x     <= 0;
        write_y     <= 0;
        write_depth <= 0;
        write_color <= 0;
    end else begin
        // Save the incoming pixel while its stored depth is read.
        saved_valid <= pixel_inside;
        saved_x     <= pixel_x;
        saved_y     <= pixel_y;
        saved_depth <= new_depth;
        saved_color <= new_color;

        // Default: do not write.
        write_en <= 0;

        // Compare the saved pixel with its returned stored depth.
        if (saved_valid && (saved_depth < stored_depth)) begin
            write_en    <= 1;
            write_x     <= saved_x;
            write_y     <= saved_y;
            write_depth <= saved_depth;
            write_color <= saved_color;
        end
    end
end

endmodule