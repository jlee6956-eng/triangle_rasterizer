module bounding_box_scanner (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,

    input  logic [7:0] min_x,
    input  logic [7:0] max_x,
    input  logic [6:0] min_y,
    input  logic [6:0] max_y,

    output logic [7:0] pixel_x,
    output logic [6:0] pixel_y,
    output logic       pixel_valid,
    output logic       busy,
    output logic       done
);

logic [7:0] min_x_reg;
logic [7:0] max_x_reg;
logic [6:0] min_y_reg;
logic [6:0] max_y_reg;

always_ff @(posedge clk) begin
    if (rst) begin
        pixel_x     <= 0;
        pixel_y     <= 0;
        pixel_valid <= 0;
        busy        <= 0;
        done        <= 0;

        min_x_reg   <= 0;
        max_x_reg   <= 0;
        max_y_reg   <= 0;
        min_y_reg <= 0;
    end else begin
        // Default: done is only a one-cycle pulse
        done <= 0;

        if (start && !busy) begin
            // Start scanning a new box
            min_x_reg <= min_x;
            max_x_reg <= max_x;
            max_y_reg <= max_y;
            min_y_reg <= min_y;

            pixel_x     <= min_x;
            pixel_y     <= min_y;
            pixel_valid <= 1;
            busy        <= 1;

        end else if (busy) begin
            // Finish after outputting the bottom-right pixel
            if ((pixel_x == max_x_reg) &&
                (pixel_y == max_y_reg)) begin

                pixel_valid <= 0;
                busy        <= 0;
                done        <= 1;

            // Move to the beginning of the next row
            end else if (pixel_x == max_x_reg) begin
                pixel_x <= min_x_reg;
                pixel_y <= pixel_y + 1'b1;

            // Move to the next pixel in this row
            end else begin
                pixel_x <= pixel_x + 1'b1;
            end

        end else begin
            // Idle
            pixel_valid <= 0;
        end
    end
end

endmodule