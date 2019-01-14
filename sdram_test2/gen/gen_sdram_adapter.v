module gen_sdram_adapter(
// HOST PART
    // Control inputs - clock and frame reset
    input           iclk_50,
    input           ireset,
    
    // SDRAM side
    output          oreq,
    output  [21:0]  oaddress,
    output [127:0]  odata,
    input           iack,
    
    // Generator side
    input    [9:0]  i_current_x,
    input    [9:0]  i_current_y,
    input           i_active_d,
    
    input    [3:0]  i_red,
    input    [3:0]  i_green,
    input    [3:0]  i_blue
);

reg     [7:0]   state           = 8'b00000001;
reg     [7:0]   next_state      = 8'b00000001;
reg             write_request;

reg   [127:0]   cache1          = 128'b1;
reg   [127:0]   cache2          = 128'b1;

wire   [24:0]   current_pixel;
wire   [63:0]   pixel_offset;
wire   [63:0]   current_bank;
wire   [63:0]   future_bank;
wire  [127:0]   offset_mask;
wire            fetch_next;

assign current_pixel    = 640 * i_current_y + i_current_x;
assign pixel_offset     = current_pixel % 10;
assign current_bank     = (64'h1999999A * current_pixel) >> 32;
assign future_bank      = (current_bank < 30720) ? current_bank + 1 : 0;
assign fetch_next       = (pixel_offset == 0) && i_active_d;

assign oreq             = write_request;
assign oaddress         = future_bank;
assign odata            = (state < 6'b001000) ? cache2 : cache1;

always @(negedge iclk_50)
begin
    if(ireset)
        state <= #1 8'b00000001;
    else
        state <= #1 next_state;
end

always @(state or fetch_next or iack)
begin
    case(state)
        8'b00000001:
            if(fetch_next)
                next_state  <= 8'b00000010;
            else                
                next_state  <= 8'b00000001;
        8'b00000010:
            next_state      <= 8'b00000100;
        8'b00000100:
            if(iack)
                next_state  <= 8'b00001000;
            else
                next_state  <= 8'b00000010;
        8'b00001000:
            next_state      <= 8'b00010000;
            
        8'b00010000:
            if(fetch_next)
                next_state  <= 8'b00100000;
            else                
                next_state  <= 8'b00010000;
        8'b00100000:
            next_state      <= 8'b01000000;
        8'b01000000:
            if(iack)
                next_state  <= 8'b10000000;
            else
                next_state  <= 8'b00100000;
        8'b10000000:
            next_state      <= 8'b00000001;
        default:
            next_state      <= 8'b00000001;
    endcase
end

always @(state)
begin
    case(state)
        8'b00000001:
        begin
            write_request   <= #1 1'b0;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end        
        8'b00000010:
        begin
            write_request   <= #1 1'b1; 
 
            cache1          <= #1 ((cache1 << 12) | {116'b0, i_red, i_green, i_blue});
            cache2          <= #1 cache2;
        end
        8'b00000100:
        begin
            write_request   <= #1 1'b1;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end
        8'b00001000:
        begin
            write_request   <= #1 1'b0;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end
        
        8'b00010000:
        begin
            write_request   <= #1 1'b0;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end        
        8'b00100000:
        begin
            write_request   <= #1 1'b1;
            
            cache1          <= #1 cache1;
            cache2          <= #1 ((cache2 << 12) | {116'b0, i_red, i_green, i_blue});
        end
        8'b01000000:
        begin
            write_request   <= #1 1'b1;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end
        8'b10000000:
        begin
            write_request   <= #1 1'b0;
            
            cache1          <= #1 cache1;
            cache2          <= #1 cache2;
        end 
    endcase
end

endmodule
