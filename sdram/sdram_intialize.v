//  SDRAM Settings
//  Write Bust      -- Single Location
//  CAS Latency     -- 2
//  Burst           -- Sequential 
//  Burst Length    -- 1
module sdram_initalize(	
    input                       iclk,
    input                       ireset,
    output                      odram_ready,
    output		          		DRAM_CLK,
    output		          		DRAM_CKE,
    output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CS_N,
	output		          		DRAM_RAS_N,
	output		          		DRAM_WE_N,
    output		          		DRAM_LDQM,
    output		          		DRAM_UDQM,
    output 		    [15:0]		DRAM_DQ
);

reg     [6:0]   state       = 7'b0000001;
reg     [3:0]   command     = 4'h0;
reg     [12:0]  address;
reg     [1:0]   bank        = 2'b00;
reg             ready       = 1'b0;
reg     [3:0]   ref_cycles  = 4'h0;

assign DRAM_CLK                                         = iclk;
assign odram_ready                                      = ready;
assign DRAM_ADDR                                        = address;
assign DRAM_BA                                          = bank;
assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = command;
assign DRAM_LDQM                                        = 1'b1;
assign DRAM_UDQM                                        = 1'b1;
assign DRAM_DQ                                          = 16'h0000;
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
                state           <= 7'b0000100;
            7'b0000100:
            begin
                ref_cycles      <= 4'h0;
                state           <= 7'b0001000;
            end
            7'b0001000:
                if(ref_cycles > 7)
                    state       <= 7'b0010000;
                else 
                begin
                    ref_cycles  <= ref_cycles + 1'b1;
                    state       <= 7'b0000100;
                end
            7'b0010000:
                state           <= 7'b0100000;
            7'b0100000:
                state           <= 7'b0100000;
            7'b1000000:
                state           <= 7'b1000000;
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
            ready               <= 1'b0;            
        end
        7'b0000010:
        begin
            command             <= 4'b0010;
            address             <= 13'b0010000000000;   
            bank                <= 2'b11;
            ready               <= 1'b0;  
        end
        7'b0000100:
        begin
            command             <= 4'b0001;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            ready               <= 1'b0; 
        end
        7'b0001000:
        begin
            command             <= 4'b0111;
            address             <= 13'b0000000000000;   
            bank                <= 2'b00;
            ready               <= 1'b0; 
        end
        7'b0010000:
        begin
            command             <= 4'b0000;
            bank                <= 2'b00;    
            address             <= 13'b0001001000000;
            ready               <= 1'b0;
        end
        7'b0100000:
        begin
            command             <= 4'b0111;
            bank                <= 2'b00;    
            address             <= 13'b0000000000000; 
            ready               <= 1'b0;
        end
        7'b1000000:
        begin
            command             <= 4'b0111;
            bank                <= 2'b00;    
            address             <= 13'b0000000000000; 
            ready               <= 1'b1;
        end
    endcase
end

endmodule
