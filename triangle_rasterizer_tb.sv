`timescale 1ns/1ps
module triangle_rasterizer_tb;

logic clk;
logic rst;

logic clear_start;
logic clear_busy;
logic clear_done;

logic triangle_start;

logic [7:0] x0, x1, x2;
logic [6:0] y0, y1, y2;

logic [15:0] triangle_depth;
logic [11:0] triangle_color;

logic triangle_busy;
logic triangle_done;

logic [7:0] display_x;
logic [6:0] display_y;
logic [11:0] display_color;

wire [15:0] debug_depth_10_10;
wire [11:0] debug_color_10_10;

assign debug_depth_10_10 =
    dut.depth_buffer_inst.memory[(10 * 160) + 10];
assign debug_color_10_10 =
    dut.framebuffer_inst.memory[(10 * 160) + 10];

wire [15:0] debug_depth_55_18;
wire [11:0] debug_color_55_18;

assign debug_depth_55_18 =
    dut.depth_buffer_inst.memory[(18 * 160) + 55];

assign debug_color_55_18 =
    dut.framebuffer_inst.memory[(18 * 160) + 55];

triangle_rasterizer dut (
    .clk            (clk),
    .rst            (rst),

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

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, triangle_rasterizer_tb);
end




initial begin
    // Initialize all testbench inputs
    rst            = 1;
    clear_start    = 0;
    triangle_start = 0;

    x0 = 8'd85;
    y0 = 7'd42;

    x1 = 8'd25;
    y1 = 7'd9;

    x2 = 8'd54;
    y2 = 7'd4;

    triangle_depth = 16'h5552;
    triangle_color = 12'hAAA;

    display_x = 8'd55;
    display_y = 7'd18;

    // Hold reset for two clock cycles
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // Start clearing the depth buffer
    @(negedge clk);
    clear_start = 1;

    @(negedge clk);
    clear_start = 0;

    // Wait until all 19,200 depth locations are cleared
    wait (clear_done == 1);

    // Start drawing the triangle
    @(negedge clk);
    triangle_start = 1;

    @(negedge clk);
    triangle_start = 0;

    // Wait until the complete triangle pipeline finishes
    wait (triangle_done == 1);

    // Allow time for the synchronous framebuffer read
    repeat (5) @(posedge clk);

    $finish;
end
endmodule