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

parameter PIXEL_SIZE = 4;
parameter CACHE_LENGTH = 128 / PIXEL_SIZE;

reg     [9:0]   state           = 10'b0000000001;
reg     [9:0]   next_state      = 10'b0000000001;
reg             write_request;

reg   [127:0]   cache1          = 128'b1;
reg   [127:0]   cache2          = 128'b1;
reg             cache_swt       = 1'b0;

reg    [15:0]   counter         = 16'h0;
reg             ctr_reset       = 1'b0;

wire   [24:0]   current_pixel;
wire   [63:0]   pixel_offset;
wire   [63:0]   current_bank;
wire   [63:0]   future_bank;
wire  [127:0]   offset_mask;
wire            fetch_next;
wire            cspace_fin;     

wire            red;
wire    [1:0]   green;
wire            blue;


assign current_pixel    = 640 * i_current_y + i_current_x;
assign pixel_offset     = current_pixel % CACHE_LENGTH;
assign current_bank     = current_pixel / CACHE_LENGTH;
assign future_bank      = (current_bank < 30720) ? current_bank + 1 : 0;
assign fetch_next       = (pixel_offset == 0);

assign oreq             = write_request;
assign oaddress         = future_bank;
assign odata            = (cache_swt) ? cache1 : cache2;
assign cspace_fin       = (counter >= 2 * CACHE_LENGTH);

assign red              = i_red[0] | i_red[1] | i_red[2] | i_red[3];
assign green            = {i_green[0] | i_green[1], i_green[2] |  i_green[3]};
assign blue             = i_blue[0] | i_blue[1] | i_blue[2] | i_blue[3];


always @(negedge iclk_50 or posedge ctr_reset)
begin
    if(ctr_reset)
        counter <= #1 16'h0;
    else
        counter <= #1 (counter + 1'b1);
end

always @(negedge iclk_50)
begin
    if(ireset)
        state <= #1 10'b0000000001;
    else
        state <= #1 next_state;
end

always @(state or fetch_next or iack or cspace_fin)
begin
    case(state)
        10'b0000000001:
            if(fetch_next)
                next_state  <= 10'b0000000010;
            else                
                next_state  <= 10'b0000000001;
        10'b0000000010:
            next_state      <= 10'b0000000100;
        10'b0000000100:
            if(iack)
                next_state  <= 10'b0000001000;
            else
                next_state  <= 10'b0000000010;
        10'b0000001000:
            if(cspace_fin)
                next_state  <= 10'b0000100000;
            else
                next_state  <= 10'b0000010000;
        10'b0000010000:
            next_state      <= 10'b0000001000;
            
            
        10'b0000100000:
            if(fetch_next)
                next_state  <= 10'b0001000000;
            else                
                next_state  <= 10'b0000100000;
        10'b0001000000:
            next_state      <= 10'b0010000000;
        10'b0010000000:
            if(iack)
                next_state  <= 10'b0100000000;
            else
                next_state  <= 10'b0001000000;
        10'b0100000000:
            if(cspace_fin)
                next_state  <= 10'b0000000001;
            else
                next_state  <= 10'b1000000000;
        10'b1000000000:
            next_state      <= 10'b0100000000;
        default:
            next_state      <= 10'b0000000001;
    endcase
end

always @(state)
begin
    case(state)
        10'b0000000001:
        begin
            write_request   <= #1 1'b0;
            
            cache_swt       <= #1 1'b0;
            ctr_reset       <= #1 1'b1;
        end        
        10'b0000000010:
        begin
            write_request   <= #1 1'b1;  
            
            cache1          <= #1 ((cache1 << PIXEL_SIZE) | {124'b0, red, green, blue});
            cache_swt       <= #1 1'b0;
            ctr_reset       <= #1 1'b0;
        end
        10'b0000000100:
        begin
            write_request   <= #1 1'b1;            
           
            cache_swt       <= #1 1'b0;
            ctr_reset       <= #1 1'b0;
        end
        10'b0000001000:
        begin
            write_request   <= #1 1'b0;            

            cache1          <= #1 ((cache1 << PIXEL_SIZE) | {124'b0, red, green, blue});
            cache_swt       <= #1 1'b0;
            ctr_reset       <= #1 1'b0;
        end
        10'b0000010000:
        begin
            write_request   <= #1 1'b0;
            
            cache_swt       <= #1 1'b0;
            ctr_reset       <= #1 1'b0;
        end
        
        
        10'b0000100000:
        begin
            write_request   <= #1 1'b0;
            
            cache_swt       <= #1 1'b1;
            ctr_reset       <= #1 1'b1;
        end        
        10'b0001000000:
        begin
            write_request   <= #1 1'b1;            
            
            cache2          <= #1 ((cache2 << PIXEL_SIZE) | {124'b0, red, green, blue});
            cache_swt       <= #1 1'b1;
            ctr_reset       <= #1 1'b0;
        end
        10'b0010000000:
        begin
            write_request   <= #1 1'b1;
            
            cache_swt       <= #1 1'b1;
            ctr_reset       <= #1 1'b0;
        end
        10'b0100000000:
        begin
            write_request   <= #1 1'b0;            
            
            cache2          <= #1 ((cache2 << PIXEL_SIZE) | {124'b0, red, green, blue});
            cache_swt       <= #1 1'b1;
            ctr_reset       <= #1 1'b0;
        end 
        10'b1000000000:
        begin
            write_request   <= #1 1'b0;            
           
            cache_swt       <= #1 1'b1;
            ctr_reset       <= #1 1'b0;
        end 
    endcase
end

endmodule
