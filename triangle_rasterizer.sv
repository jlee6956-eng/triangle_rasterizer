module triangle_rasterizer (
    input logic clk,
    input logic rst,

    // Clear the depth buffer
    input logic clear_start,
    output logic clear_busy,
    output logic clear_done,

    // Begin drawing one triangle
    input logic triangle_start,

    input logic [7:0] x0,
    input logic [6:0] y0,
    input logic [7:0] x1,
    input logic [6:0] y1,
    input logic [7:0] x2,
    input logic [6:0] y2,

    input logic [15:0] triangle_depth,
    input logic [11:0] triangle_color,

    output logic triangle_busy,
    output logic triangle_done
);

    // Module instances and connecting signals

endmodule