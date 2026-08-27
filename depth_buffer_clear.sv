module depth_buffer_clear (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,

    output logic        clear_busy,
    output logic        clear_done,

    output logic        clear_write_en,
    output logic [7:0]  clear_x,
    output logic [6:0]  clear_y,
    output logic [15:0] clear_depth
);

assign clear_depth = 16'hFFFF;

always_ff @(posedge clk) begin
    if (rst) begin
        clear_busy     <= 0;
        clear_done     <= 0;
        clear_write_en <= 0;
        clear_x        <= 0;
        clear_y        <= 0;
    end else begin
        // clear_done is only a one-clock pulse
        clear_done <= 0;

        if (start && !clear_busy) begin
            clear_busy     <= 1;
            clear_write_en <= 1;
            clear_x        <= 0;
            clear_y        <= 0;

        end else if (clear_busy) begin
            // The final location is being written this clock
            if ((clear_x == 159) && (clear_y == 119)) begin
                clear_busy     <= 0;
                clear_write_en <= 0;
                clear_done     <= 1;

            end else if (clear_x == 159) begin
                // Move to the beginning of the next row
                clear_x <= 0;
                clear_y <= clear_y + 1'b1;

            end else begin
                // Move to the next column
                clear_x <= clear_x + 1'b1;
            end

        end else begin
            clear_write_en <= 0;
        end
    end
end

endmodule