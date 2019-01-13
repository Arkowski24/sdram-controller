module vga_sdram_adapter(
// HOST PART
    // Control inputs - clock and frame reset
    input           iclk_50,
    input           ireset,
    
    // SDRAM side
    output          oread_req,
    output  [21:0]  oread_address,
    input  [127:0]  iread_data,
    input           iread_ack,
    
    // VGA Controller side
    input    [9:0]  i_current_x,
    input    [9:0]  i_current_y,
    input           i_active_d,
    
    output   [3:0]  o_red,
    output   [3:0]  o_green,
    output   [3:0]  o_blue
);

reg     [7:0]   state           = 8'b00000001;
reg     [7:0]   next_state      = 8'b00000001;

reg   [127:0]   cache1          = 128'b1;
reg   [127:0]   cache2          = 128'b1;
reg             cache_swt       = 1'b0;

wire   [24:0]   current_pixel;
wire    [3:0]   pixel_offset;
wire   [21:0]   current_bank;
wire   [21:0]   future_bank;
wire            fetch_next;
reg             read_request;


assign current_pixel    = 640 * i_current_y + i_current_x;
assign pixel_offset     = current_pixel - current_bank * 10;

assign current_bank     = current_pixel / 10;
assign future_bank      = (current_bank < 30720) ? (current_bank + 1) : 0;

assign fetch_next       = (pixel_offset == 0) && i_active_d;

assign oread_req        = read_request;
assign oread_address    = future_bank;

assign o_red            = cache_swt ? cache1[11:8]  : cache2[11:8];
assign o_green          = cache_swt ? cache1[7:4]   : cache2[7:4];
assign o_blue           = cache_swt ? cache1[3:0]   : cache2[3:0];

always @(posedge iclk_50)
begin
    if(ireset == 1'b1)
        state <= #1 8'b00000001;
    else
        state <= #1 next_state;
end

always @(state or fetch_next or iread_ack)
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
            if(iread_ack)
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
            if(iread_ack)
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
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;
        end        
        8'b00000010:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b0;
            
        end
        8'b00000100:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b0;
            
            cache2          <= #1 cache2 >> 12;
        end
        8'b00001000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;
            
            cache1          <= #1 iread_data;
        end
        
        8'b00010000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;
        end        
        8'b00100000:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b1;
        end
        8'b01000000:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b1;
            
            cache1          <= #1 cache1 >> 12;
        end
        8'b10000000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;
            
            cache2          <= #1 iread_data;
        end
    endcase
end

endmodule
