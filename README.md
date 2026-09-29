# Hardware Triangle Rasterizer with Z-Buffer and VGA Output (SystemVerilog)

A fixed-function 3D graphics pipeline stage in SystemVerilog. It takes a triangle (3 vertices, a depth, and a color), finds every pixel it covers, resolves visibility with a depth buffer, writes the survivors to a framebuffer, and scans the framebuffer out to a 640×480 VGA display.

## Pipeline

```
triangle cmd ─► Bounding Box ─► Box Scanner ─► Inside Test ─► Depth Test ─┬─► Depth Buffer (16-bit)
(x,y ×3,                         1 px/clk      edge functions  2-stage    └─► Framebuffer  (12-bit RGB)
 depth, color)                                                                     │
                                                                                   ▼
                                                              VGA timing ─► 640×480 @ 60 Hz
```

| Module | Role |
|---|---|
| `triangle_bounding_box.sv` | Combinational min/max of the three vertices |
| `bounding_box_scanner.sv` | Walks the box row by row, emitting one pixel coordinate per clock |
| `triangle_inside_test.sv` | Edge-function coverage test |
| `depth_test.sv` | Reads the stored depth, compares it, and issues the write |
| `depth_buffer.sv` | 160×120 × 16-bit RAM with synchronous read |
| `depth_buffer_clear.sv` | Resets every depth entry to `0xFFFF` (the far plane) |
| `framebuffer.sv` | 160×120 × 12-bit RAM; one port for the rasterizer, one for VGA |
| `triangle_rasterizer.sv` | Ties the pipeline together and generates `busy`/`done` |
| `vga_timing.sv` | 640×480 @ 60 Hz sync generator (800×525 total, 25 MHz pixel clock) |
| `top_module.sv` | Board top: clock divider, scene FSM, VGA color output |

## How it works

### Coverage: edge functions

For each edge $v_a \to v_b$ and candidate pixel $p$:

$$
E_{ab}(p) = (p_x - v_{a,x})(v_{b,y} - v_{a,y}) - (p_y - v_{a,y})(v_{b,x} - v_{a,x})
$$

The pixel is inside when all three edge functions share a sign. Accepting both all-positive and all-negative makes the test work for clockwise and counter-clockwise triangles.

**Example:** for vertices $(85,42)$, $(25,9)$, $(54,4)$, pixel $(55,18)$ gives the same sign on all three edges, so it is drawn. Pixel $(10,10)$ lies outside the bounding box and is never scanned.

### Visibility: depth test

The depth buffer has a one-cycle read latency. The depth test registers each pixel's coordinate, depth, and color while its stored depth is fetched, then compares on the next clock:

$$
\text{write if } z_\text{new} < z_\text{stored}
$$

Smaller values are closer. Clearing to `0xFFFF` means the first triangle drawn at any pixel always wins. Because the scanner finishes before the last depth comparison does, `triangle_done` is delayed by two cycles so it fires only after the final write lands.

### Display

The 160×120 framebuffer is upscaled 4× to 640×480 by dropping the two low bits of the VGA coordinates. Each stored pixel appears as a 4×4 block, which keeps the frame at 19,200 entries so it fits in block RAM.

## Simulation

The testbench clears the depth buffer, then draws a triangle at depth `0x5552`. It then redraws the same triangle closer (`0x3555`) in a new color and checks that the closer one overwrites the first.

```bash
iverilog -g2012 -o tri triangle_rasterizer_tb.sv triangle_rasterizer.sv \
    triangle_bounding_box.sv bounding_box_scanner.sv triangle_inside_test.sv \
    depth_test.sv depth_buffer.sv depth_buffer_clear.sv framebuffer.sv && vvp tri
# → First triangle passed
# → Closer triangle correctly overwrote first triangle
```

## On hardware

`top_module.sv` targets a 100 MHz board with a 4-bit-per-channel VGA port. It divides the clock down to 25 MHz for VGA timing, then runs a scene FSM that clears the depth buffer, draws two overlapping triangles, and displays the result.

## Next steps

- Per-vertex depth and color with barycentric interpolation (currently each triangle has one flat depth and color)
- Impelementation on actual VGA port
- Incremental edge-function evaluation (add a constant per step instead of multiplying per pixel)
- Framebuffer clear and double buffering for animation
- Proper clock-domain crossing between the 100 MHz rasterizer and the 25 MHz VGA side
