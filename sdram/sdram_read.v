module sdram_read(
    input                       iclk,
    input                       ireset,
    input           [12:0]      irow,
    input            [9:0]      icolumn,
    input            [1:0]      ibank,
    output 		    [15:0]		odata,
    output                      oread_fin,
    
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
    input 		    [15:0]		DRAM_DQ
);

reg      [6:0]  state   = 7'b0000001;
reg      [3:0]  command = 4'h0;
reg     [12:0]  address = 13'h0;
reg      [1:0]  bank    = 2'b00;
reg     [15:0]  data    = 16'h0000;

reg             ready       = 1'b0;
reg      [3:0]  nop_count   = 4'h0;
reg      [1:0]  dqm         = 2'b11;

assign DRAM_CLK                                         = iclk;
assign oread_fin                                        = ready;
assign odata                                            = data;
assign DRAM_ADDR                                        = address;
assign DRAM_BA                                          = bank;
assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = command;
assign {DRAM_UDQM, DRAM_LDQM}                           = dqm;
assign DRAM_CKE                                         = 1'b1;

always @(posedge iclk or posedge ireset)
begin
    if(ireset)
        state       <= 7'b0000001;
    else
        case(state)
            7'b0000001:
                state           <= 7'b0000010;
            7'b0000010:   
                begin
                    state       <= 7'b0000100;
                    nop_count   <= 4'h0;
                end
            7'b0000100:
                if(nop_count > 3)
                    state       <= 7'b0001000;
                else 
                begin
                    nop_count   <= nop_count + 1'b1;
                    state       <= 7'b0000100;  
                end
            7'b0001000:
                begin
                    state       <= 7'b0010000;
                    nop_count   <= 4'h0;
                end
            7'b0010000:
                if(nop_count > 2)
                    state       <= 7'b0100000;
                else 
                begin
                    nop_count   <= nop_count + 1'b1;
                    state       <= 7'b0010000;  
                end
            7'b0100000:
                state           <= 7'b1000000;
            7'b1000000:
                state           <= 7'b0100000;
        endcase
end

always @(state)
begin
    case(state)
        7'b0000001:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;
            bank                <= 2'b00;
            dqm                 <= 2'b11;
            ready               <= 1'b0;
        end
        7'b0000010:
        begin
            command             <= 4'b0011;
            address             <= irow;
            bank                <= ibank;
            dqm                 <= 2'b11;
            ready               <= 1'b0;
        end
        7'b0000100:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            dqm                 <= 2'b11;
            ready               <= 1'b0;
        end
        7'b0001000:
        begin
            command             <= 4'b0101;
            address             <= {3'b001, icolumn};
            bank                <= ibank;
            dqm                 <= 2'b00;
            ready               <= 1'b0;
        end
        7'b0010000:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            dqm                 <= 2'b11;
            ready               <= 1'b0;
        end
        7'b0100000:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            dqm                 <= 2'b11;
            data                <= DRAM_DQ;
            ready               <= 1'b1;
        end
        7'b1000000:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            dqm                 <= 2'b11;
            data                <= data;
            ready               <= 1'b1;
        end
    endcase
end

endmodule
