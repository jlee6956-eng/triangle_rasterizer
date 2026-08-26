module framebuffer (
    input  logic        clk,

    // Rasterizer write port
    input  logic        write_en,
    input  logic [7:0]  write_x,
    input  logic [6:0]  write_y,
    input  logic [11:0] write_color,

    // VGA read port
    input  logic [7:0]  read_x,
    input  logic [6:0]  read_y,
    output logic [11:0] read_color
);

localparam int WIDTH  = 160;
localparam int HEIGHT = 120;
localparam int DEPTH  = WIDTH * HEIGHT;

logic [11:0] memory [0:DEPTH-1];

logic [$clog2(DEPTH)-1:0] write_pos;
logic [$clog2(DEPTH)-1:0] read_pos;

assign write_pos = write_y * WIDTH + write_x;
assign read_pos  = read_y  * WIDTH + read_x;

always_ff @(posedge clk) begin
    if (write_en) begin
        memory[write_pos] <= write_color;
    end

    read_color <= memory[read_pos];
end

endmodule