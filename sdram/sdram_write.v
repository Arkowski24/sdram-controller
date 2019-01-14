module sdram_write(
    input                       iclk,
    input                       ireset,
    input                       ireq,
    input                       ienb,
    output                      ofin,
    
    input           [12:0]      irow,
    input            [9:0]      icolumn,
    input            [1:0]      ibank,
    input 		   [127:0]		idata,
    
    output		          		DRAM_CLK,
    output		          		DRAM_CKE,
    output  	    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CS_N,
	output		          		DRAM_RAS_N,
	output		          		DRAM_WE_N,
    output		          		DRAM_LDQM,
    output		          		DRAM_UDQM,
    output 		    [15:0]		DRAM_DQ
);

reg      [6:0]  state       = 7'b0000001;
reg      [6:0]  next_state;

reg      [3:0]  command     = 4'h0;
reg     [12:0]  address     = 13'h0;
reg      [1:0]  bank        = 2'b00;
reg    [127:0]  data        = 128'h0;
reg      [1:0]  dqm         = 2'b11;

reg             ready       = 1'b0;

reg      [7:0]  counter     = 8'h0;
reg             ctr_reset   = 0;

wire    data_count;

assign ofin                                             = ready;

assign DRAM_ADDR                                        = ienb ? address        : 13'bz;
assign DRAM_BA                                          = ienb ? bank           : 2'bz;
assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = ienb ? command        : 4'bz;
assign {DRAM_UDQM, DRAM_LDQM}                           = ienb ? dqm            : 2'bz;
assign DRAM_CLK                                         = ienb ? ~iclk          : 1'bz;
assign DRAM_CKE                                         = ienb ? 1'b1           : 1'bz;
assign DRAM_DQ                                          = ienb ? data[127:112]  : 16'bz;

always @(posedge iclk or posedge ctr_reset)
begin
    if(ctr_reset)
        counter <= #1 8'h0;
    else
        counter <= #1 (counter + 1'b1);
end

assign data_count = (counter == 5);

always @(posedge iclk)
begin
    if(ireset == 1'b1)
        state <= #1 7'b0000001;
    else
        state <= #1 next_state;
end

always @(state or ireq or data_count)
begin
    case(state)
        //IDLE
        7'b0000001:
            if(ireq)
                next_state   <= 7'b0000010;
            else
                next_state   <= 7'b0000001;
        //ACTIVE
        7'b0000010:
            next_state       <= 7'b0000100;
        //NOP
        7'b0000100:
            next_state       <= 7'b0001000;
        //WRITE
        7'b0001000:
                next_state   <= 7'b0010000;                
        //WRITING   
        7'b0010000:
            if(data_count)
                next_state   <= 7'b0100000;
            else
                next_state   <= 7'b0010000;
        //NOP
        7'b0100000:
            next_state       <= 7'b1000000;
        //NOP - FIN
        7'b1000000:
            next_state       <= 7'b0000001;
        default:
            next_state       <= 7'b0000001;
    endcase
end

always @(posedge iclk)
begin
    case(state)
        //IDLE
        7'b0000001:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;
            bank                <= #1 2'b00;
            dqm                 <= #1 2'b11;
            data                <= #1 data;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        //ACTIVE
        7'b0000010:
        begin
            command             <= #1 4'b0011;
            address             <= #1 irow;
            bank                <= #1 ibank;
            dqm                 <= #1 2'b11;
            data                <= #1 idata;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        //NOP
        7'b0000100:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            dqm                 <= #1 2'b11;
            data                <= #1 data;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b1;
        end
        //WRITE
        7'b0001000:
        begin
            command             <= #1 4'b0100;
            address             <= #1 {3'b001, icolumn};
            bank                <= #1 ibank;
            dqm                 <= #1 2'b00;
            data                <= #1 data;
            ready               <= #1 1'b0; 
            
            ctr_reset           <= #1 1'b1;
        end
        //WRITING  
        7'b0010000:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            dqm                 <= #1 2'b00;
            data                <= #1 (data << 16);
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        //NOP
        7'b0100000:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            dqm                 <= #1 2'b11;
            data                <= #1 data;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        //NOP - FIN
        7'b1000000:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            dqm                 <= #1 2'b11;
            data                <= #1 data;
            ready               <= #1 1'b1;
            
            ctr_reset           <= #1 1'b0;
        end
    endcase
end

endmodule
