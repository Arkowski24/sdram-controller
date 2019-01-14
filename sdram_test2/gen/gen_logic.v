//DRAW SQUARE
module gen_logic(
    // X and Y of current pixel
    input wire [9:0]    i_x,
    input wire [9:0]    i_y,
    
    output wire  [3:0]  o_red,
    output wire  [3:0]  o_green,
    output wire  [3:0]  o_blue
);

// Rectangle parameters
parameter X_LENGTH	= 10'd 100;
parameter X_OFFSET	= 10'd 100;
parameter X_TOTAL	= X_OFFSET + X_LENGTH;
parameter Y_LENGTH	= 10'd 100;
parameter Y_OFFSET	= 10'd 100;
parameter Y_TOTAL	= Y_OFFSET + Y_LENGTH;

// Color of the rectangle and background
parameter RECT_R	= 4'b1111;
parameter RECT_G	= 4'b0000;
parameter RECT_B	= 4'b0000;
parameter BACK_R	= 4'b0000;
parameter BACK_G	= 4'b0000;
parameter BACK_B	= 4'b1111;

wire in_x;
wire in_y;
wire in_square;

assign in_x         = (i_x >= X_OFFSET && i_x  <= X_TOTAL);
assign in_y         = (i_y >= Y_OFFSET && i_y  <= Y_TOTAL);
assign in_square    = in_x && in_y;

assign o_red        = in_square  ? RECT_R : BACK_R;
assign o_green      = in_square  ? RECT_G : BACK_G;
assign o_blue       = in_square  ? RECT_B : BACK_B;

endmodule
