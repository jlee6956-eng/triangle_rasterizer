module triangle_bounding_box (
    input  logic [7:0] x0,
    input  logic [6:0] y0,

    input  logic [7:0] x1,
    input  logic [6:0] y1,

    input  logic [7:0] x2,
    input  logic [6:0] y2,

    output logic [7:0] min_x,
    output logic [7:0] max_x,
    output logic [6:0] min_y,
    output logic [6:0] max_y
);

always_comb begin
    min_x = x0;

    if (x1 < min_x)
        min_x = x1;

    if (x2 < min_x)
        min_x = x2;

    max_x = x0;

    if (x1 > max_x)
        max_x = x1;

    if (x2 > max_x)
        max_x = x2;

    min_y = y0;

    if (y1 < min_y)
        min_y = y1;

    if (y2 < min_y)
        min_y = y2;

    max_y = y0;

    if (y1 > max_y)
        max_y = y1;

    if (y2 > max_y)
        max_y = y2;
end

endmodule