module gen_controller(
// HOST PART
    // Control inputs - clock and frame reset
    input wire          i_clk_25,
    input wire          i_rst,
    // Color input data
    output wire  [3:0]  o_red,
    output wire  [3:0]  o_green,
    output wire  [3:0]  o_blue,
    // X and Y of current pixel
    output wire [9:0]   o_current_x,
    output wire [9:0]   o_current_y,
    output wire         o_active_d
);

// VGA TIMINGS
//  Horizontal Parameters
localparam  H_FRONT = 16;
localparam  H_SYNC  = 96;
localparam  H_BACK  = 48;
localparam  H_ACT   = 640; 
localparam  H_BLANK = H_FRONT + H_SYNC + H_BACK;
localparam  H_TOTAL = H_FRONT + H_SYNC + H_BACK + H_ACT;
//  Vertical Parameters
localparam  V_FRONT = 11;
localparam  V_SYNC  = 2;
localparam  V_BACK  = 31;
localparam  V_ACT   = 480;
localparam  V_BLANK = V_FRONT + V_SYNC + V_BACK;
localparam  V_TOTAL = V_FRONT + V_SYNC + V_BACK + V_ACT;

// Internals - 11 bits to be sure no overflow happens
reg [10:0] h_count;
reg [10:0] v_count;

reg        oVGA_HS;

// VGA Color Data
assign o_red        = 4'b1111;
assign o_green      = 4'b0000;
assign o_blue       = 4'b0000;

// HOST OUTPUT LOGIC
assign o_current_x  = (h_count >= H_BLANK) ? (h_count - H_BLANK) : 10'b0;
assign o_current_y  = (v_count >= V_BLANK) ? (v_count - V_BLANK) : 10'b0;
assign o_active_d   = (h_count >= H_BLANK && h_count < H_TOTAL) && (v_count >= V_BLANK && v_count < V_TOTAL);

// VGA HS - active low
always @ (posedge i_clk_25 or posedge i_rst)
begin
    if (i_rst)
    begin
        h_count <= 0;
        oVGA_HS <= 1'b1;
    end
    else
    begin
        if (h_count < H_TOTAL)
            h_count <= h_count + 1'b1;
        else
            h_count <= 0;
            
        if (h_count == H_FRONT - 1)
            oVGA_HS <= 1'b0;
            
        if (h_count == H_FRONT + H_SYNC - 1)
            oVGA_HS <= 1'b1;
    end
end

// VGA VS - active low
always @ (posedge oVGA_HS or posedge i_rst)
begin
    if (i_rst)
    begin
        v_count <= 0;
    end
    else
    begin
        if (v_count < V_TOTAL)
            v_count <= v_count + 1'b1;
        else
            v_count <= 0;
    end
end

endmodule
