module triangle_inside_test (
    input  logic [7:0] x0,
    input  logic [6:0] y0,

    input  logic [7:0] x1,
    input  logic [6:0] y1,

    input  logic [7:0] x2,
    input  logic [6:0] y2,

    input  logic [7:0] pixel_x,
    input  logic [6:0] pixel_y,
    input  logic       pixel_valid,

    output logic       pixel_inside
);

integer px;
integer py;

integer vx0;
integer vy0;
integer vx1;
integer vy1;
integer vx2;
integer vy2;

integer e0;
integer e1;
integer e2;

always_comb begin
    // Convert the unsigned inputs to signed integers
    px = pixel_x;
    py = pixel_y;

    vx0 = x0;
    vy0 = y0;
    vx1 = x1;
    vy1 = y1;
    vx2 = x2;
    vy2 = y2;

    // Determine which side of each edge the pixel is on
    e0 = (px - vx0) * (vy1 - vy0)
       - (py - vy0) * (vx1 - vx0);

    e1 = (px - vx1) * (vy2 - vy1)
       - (py - vy1) * (vx2 - vx1);

    e2 = (px - vx2) * (vy0 - vy2)
       - (py - vy2) * (vx0 - vx2);

    pixel_inside = 1'b0;

    if (pixel_valid) begin
        pixel_inside =
            ((e0 >= 0) && (e1 >= 0) && (e2 >= 0)) ||
            ((e0 <= 0) && (e1 <= 0) && (e2 <= 0));
    end
end

endmodule