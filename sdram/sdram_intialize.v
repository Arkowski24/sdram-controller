//  SDRAM Settings
//  Write Bust      -- Single Location
//  CAS Latency     -- 2
//  Burst           -- Sequential 
//  Burst Length    -- 1
module sdram_initalize(	
    input                       iclk,
    input                       ireset,
    input                       ireq,
    input                       ienb,
    output                      ofin,
    
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

reg      [7:0]  state       = 8'b00000001;
reg      [7:0]  next_state;

reg      [3:0]  command     = 4'h0;
reg     [12:0]  address     = 13'h0;
reg      [1:0]  bank        = 2'b00;
reg      [1:0]  dqm         = 2'b11;

reg             ready       = 1'b0;

reg     [15:0]  counter     = 16'h0;
reg             ctr_reset   = 0;

wire            ref_cycles;
wire		    init_begin_counter;

assign ofin                                             = ready;

assign DRAM_ADDR                                        = ienb ? address    : 13'bz;
assign DRAM_BA                                          = ienb ? bank       : 2'bz;
assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = ienb ? command    : 4'bz;
assign {DRAM_UDQM, DRAM_LDQM}                           = ienb ? dqm        : 2'bz;
assign DRAM_CLK                                         = ienb ? ~iclk      : 1'bz;
assign DRAM_CKE                                         = ienb ? 1'b1       : 1'bz;
assign DRAM_DQ                                          = ienb ? 16'h0000   : 16'bz;

always @(posedge iclk or posedge ctr_reset)
begin
    if(ctr_reset)
        counter <= #1 16'h0;
    else
        counter <= #1 (counter + 1'b1);
end

//ref_cycles > 16 - refresh, nop - 8 times
assign ref_cycles = (counter >= 16);
assign init_begin_counter = (counter >= 10000);
//assign init_begin_counter = (counter >= 12);

always @(posedge iclk)
begin
    if(ireset == 1'b1)
        state <= #1 8'b00000001;
    else
        state <= #1 next_state;
end

always @(state or ireq or ref_cycles or init_begin_counter)
begin
    case(state)
        //IDLE
        8'b00000001:
            if(ireq)
                next_state  <= 8'b00000010;
            else
                next_state  <= 8'b00000001;
        //NOP - POWER UP
		8'b00000010:
            if(init_begin_counter)
                next_state  <= 8'b00000100;
            else
                next_state  <= 8'b00000010;
        8'b00000100:
            next_state      <= 8'b00001000;
        8'b00001000:
            next_state      <= 8'b00010000;
        8'b00010000:
            if(ref_cycles)
                next_state  <= 8'b00100000;
            else
                next_state  <= 8'b00001000;
        8'b00100000:
            next_state      <= 8'b01000000;
        8'b01000000:
            next_state      <= 8'b10000000;
        8'b10000000:
            next_state      <= 8'b10000000;
        default:
            next_state      <= 8'b00000001;
    endcase
end

always @(state)
begin
    case(state)
        8'b00000001:
        begin            
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b1;
        end
        8'b00000010:
        begin            
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        8'b00000100:
        begin
            command             <= #1 4'b0010;
            address             <= #1 13'b0010000000000;   
            bank                <= #1 2'b11;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b1;
        end
        8'b00001000:
        begin
            command             <= #1 4'b0001;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        8'b00010000:
        begin
            command             <= #1 4'b0111;
            address             <= #1 13'b0000000000000;   
            bank                <= #1 2'b00;
            ready               <= #1 1'b0;
           
            ctr_reset           <= #1 1'b0; 
        end
        8'b00100000:
        begin
            command             <= #1 4'b0000;
            bank                <= #1 2'b00;    
            address             <= #1 13'b0000000100011;
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        8'b01000000:
        begin
            command             <= #1 4'b0111;
            bank                <= #1 2'b00;    
            address             <= #1 13'b0000000000000; 
            ready               <= #1 1'b0;
            
            ctr_reset           <= #1 1'b0;
        end
        8'b10000000:
        begin
            command             <= #1 4'b0111;
            bank                <= #1 2'b00;    
            address             <= #1 13'b0000000000000; 
            ready               <= #1 1'b1;
            
            ctr_reset           <= #1 1'b0;
        end
    endcase
end

endmodule
