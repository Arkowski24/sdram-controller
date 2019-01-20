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

parameter PIXEL_SIZE = 4;
parameter CACHE_LENGTH = 128 / PIXEL_SIZE;

reg     [11:0]   state          = 12'b000000000001;
reg     [11:0]   next_state     = 12'b000000000001;

reg   [127:0]   cache1          = 128'b1;
reg   [127:0]   cache2          = 128'b1;
reg             cache_swt       = 1'b0;

reg    [15:0]   counter         = 16'h0;
reg             ctr_reset       = 1'b0;

wire   [24:0]   current_pixel;
wire    [3:0]   pixel_offset;
wire   [21:0]   current_bank;
wire   [21:0]   future_bank;
wire            fetch_next;
reg             read_request;
wire            cspace_fin;


assign current_pixel    = 640 * i_current_y + i_current_x;
assign pixel_offset     = current_pixel % CACHE_LENGTH;
assign current_bank     = current_pixel / CACHE_LENGTH;
assign future_bank      = (current_bank < 30720) ? (current_bank + 1) : 0;
assign fetch_next       = (pixel_offset > 0);

assign oread_req        = read_request;
assign oread_address    = future_bank;
assign cspace_fin       = (counter >= 2 * CACHE_LENGTH);

assign o_red            = cache_swt ? {cache1[3], cache1[3], cache1[3], cache1[3]} : {cache2[3], cache2[3], cache2[3], cache2[3]};
assign o_green          = cache_swt ? {cache1[2], cache1[2], cache1[1], cache1[1]} : {cache2[2], cache2[2], cache2[1], cache2[1]};
assign o_blue           = cache_swt ? {cache1[0], cache1[0], cache1[0], cache1[0]} : {cache2[0], cache2[0], cache2[0], cache2[0]};

always @(negedge iclk_50 or posedge ctr_reset)
begin
    if(ctr_reset)
        counter <= #1 16'h0;
    else
        counter <= #1 (counter + 1'b1);
end

always @(negedge iclk_50)
begin
    if(ireset == 1'b1)
        state <= #1 12'b000000000001;
    else
        state <= #1 next_state;
end

always @(state or fetch_next or iread_ack)
begin
    case(state)
        12'b000000000001:
            if(fetch_next)
                next_state  <= 12'b000000000010;
            else                
                next_state  <= 12'b000000000001;
        12'b000000000010:
            next_state      <= 12'b000000000100;
        12'b000000000100:
            if(iread_ack)
                next_state  <= 12'b000000001000;
            else
                next_state  <= 12'b000000000010;
        12'b000000001000:
            next_state      <= 12'b000000010000;
        12'b000000010000:
            next_state      <= 12'b000000100000;
        12'b000000100000:
            if(cspace_fin)
                next_state  <= 12'b000001000000;
            else
                next_state  <= 12'b000000010000;
            
        12'b000001000000:
            if(fetch_next)
                next_state  <= 12'b000010000000;
            else                
                next_state  <= 12'b000001000000;
        12'b000010000000:
            next_state      <= 12'b000100000000;
        12'b000100000000:
            if(iread_ack)
                next_state  <= 12'b001000000000;
            else
                next_state  <= 12'b000010000000;
        12'b001000000000:
            next_state      <= 12'b010000000000;
        12'b010000000000:
            next_state      <= 12'b100000000000;
        12'b100000000000:
            if(cspace_fin)
                next_state  <= 12'b000000000001;
            else
                next_state  <= 12'b010000000000;
        default:
            next_state      <= 12'b000000000001;
    endcase
end

always @(state)
begin
    case(state)
        12'b000000000001:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;
            
            ctr_reset       <= #1 1'b1;
        end        
        12'b000000000010:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b0;
            
            cache2          <= #1 cache2 >> PIXEL_SIZE;
            ctr_reset       <= #1 1'b0;
        end
        12'b000000000100:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b0;
            
            ctr_reset       <= #1 1'b0;
        end
        12'b000000001000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;            
            
            cache1          <= #1 iread_data;
            ctr_reset       <= #1 1'b0;
        end
        12'b000000010000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;
            
            cache2          <= #1 cache2 >> PIXEL_SIZE;
            ctr_reset       <= #1 1'b0;
        end
        12'b000000100000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b0;
            
            
            ctr_reset       <= #1 1'b0;
        end
        
        
        12'b000001000000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;
            
            ctr_reset       <= #1 1'b1;
        end        
        12'b000010000000:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b1;
            
            cache1          <= #1 cache1 >> PIXEL_SIZE;
            ctr_reset       <= #1 1'b0;
        end
        12'b00010000000:
        begin
            read_request    <= #1 1'b1;
            cache_swt       <= #1 1'b1;            
            
            ctr_reset       <= #1 1'b0;
        end
        12'b00100000000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;
            
            cache2          <= #1 iread_data;
            ctr_reset       <= #1 1'b0;
        end
        12'b01000000000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;
            
            cache1          <= #1 cache1 >> PIXEL_SIZE;
            ctr_reset       <= #1 1'b0;
        end
        12'b10000000000:
        begin
            read_request    <= #1 1'b0;
            cache_swt       <= #1 1'b1;            
            
            ctr_reset       <= #1 1'b0;
        end
    endcase
end

endmodule
