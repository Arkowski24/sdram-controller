module sdram_controller(
	input 		          		iclk,
    input 		          		ireset,
    
    input                       iwrite_req,
    input           [21:0]      iwrite_address,
    input          [127:0]      iwrite_data,
    output                      owrite_ack,
    
    input                       iread_req,
    input           [21:0]      iread_address,
    output         [127:0]      oread_data,
    output                      oread_ack,
    
	//////////// SDRAM //////////
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N
);

//=======================================================
//  REG/WIRE declarations
//=======================================================
reg      [8:0]  state       = 9'b000000001;
reg      [8:0]  next_state  = 9'b000000001;
reg      [2:0]  mul_state   = 3'b001;

reg             read_ack    = 1'b0;
reg             write_ack   = 1'b0;

//Next opperation priority - 0 = Write, 1 = Read
reg             next_prior  = 1'b0;

//SDRAM INITLIZE MODULE
reg             init_ireq   = 1'b0;
wire            init_ienb;
wire            init_fin;

//SDRAM WRITE MODULE
reg             write_ireq  = 1'b0;
wire            write_ienb;
wire    [12:0]  write_irow;
wire     [9:0]  write_icolumn;
wire     [1:0]  write_ibank;
wire            write_fin;

//SDRAM READ MODULE
reg             read_ireq   = 1'b0;
wire            read_ienb;
wire    [12:0]  read_irow;
wire     [9:0]  read_icolumn;
wire     [1:0]  read_ibank;
wire            read_fin;


//=======================================================
//  Structural coding
//=======================================================
assign {write_ibank, write_irow, write_icolumn} = {iwrite_address, 3'b0};
assign {read_ibank, read_irow, read_icolumn}    = {iread_address, 3'b0};

assign owrite_ack                               = write_ack;
assign oread_ack                                = read_ack;

assign {read_ienb, write_ienb, init_ienb}       = mul_state;

always @(posedge iclk)
begin
    if(ireset == 1'b1)
        state <= #1 9'b000000001;
    else
        state <= #1 next_state;
end

always @(state or init_fin or iwrite_req or iread_req or write_fin or read_fin or next_prior)
begin
    case(state)
        //Init States
        9'b000000001:
            next_state      <= 9'b000000010;
        9'b000000010:
            if(init_fin)
                next_state  <= 9'b000000100;
            else
                next_state  <= 9'b000000010;
                
        //Idle State
        9'b000000100:
            if(next_prior)
            begin
                if(iread_req)
                    next_state  <= 9'b001000000;
                else if(iwrite_req)
                    next_state  <= 9'b000001000;
                else
                    next_state  <= 9'b000000100;
            end
            else
            begin
                if(iwrite_req)
                    next_state  <= 9'b000001000;
                else if(iread_req)
                    next_state  <= 9'b001000000;
                else
                    next_state  <= 9'b000000100;
            end
        //Write States
        9'b000001000:
            next_state      <= 9'b000010000;    
        9'b000010000:
            if(write_fin)
                next_state  <= 9'b000100000;
            else
                next_state  <= 9'b000010000;
        9'b000100000:
            next_state      <= 9'b000000100;
            
        //Read States        `
        9'b001000000:
            next_state      <= 9'b010000000;
        9'b010000000:
            if(read_fin)
                next_state  <= 9'b100000000;
            else
                next_state  <= 9'b010000000;
        9'b100000000:
            next_state      <= 9'b000000100;
        default:
            next_state      <= 9'b000000001;
    endcase
end

always @(state)
begin
    case(state)
        //Init States
        9'b000000001:
        begin            
            init_ireq       <= 1'b1;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b001;
        end
        9'b000000010:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b001;
        end
        
        //Idle State
        9'b000000100:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b001;
        end
        
        //Write States
        9'b000001000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b1;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b010;
        end
        
        9'b000010000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b010;
        end
        9'b000100000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b1;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b010;
            next_prior      <= 1'b1;
        end
        
        //Read States
        9'b001000000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b1;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b100;
        end
        9'b010000000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 3'b100;
        end
        9'b100000000:
        begin            
            init_ireq       <= 1'b0;
            write_ireq      <= 1'b0;
            read_ireq       <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b1;
            
            mul_state       <= 3'b100;
            next_prior      <= 1'b0;
        end
    endcase
end

sdram_initalize sdram_init (
    .iclk(iclk),
    .ireset(ireset),
    
    .ireq(init_ireq),
    .ienb(init_ienb),
    
    .ofin(init_fin),
    
    .DRAM_ADDR(DRAM_ADDR),
    .DRAM_BA(DRAM_BA),
    .DRAM_CAS_N(DRAM_CAS_N),
    .DRAM_CKE(DRAM_CKE),
    .DRAM_CLK(DRAM_CLK),
    .DRAM_CS_N(DRAM_CS_N),
    .DRAM_DQ(DRAM_DQ),
    .DRAM_LDQM(DRAM_LDQM),
    .DRAM_RAS_N(DRAM_RAS_N),
    .DRAM_UDQM(DRAM_UDQM),
    .DRAM_WE_N(DRAM_WE_N)
);

sdram_write sdram_write (
    .iclk(iclk),
    .ireset(ireset),
    
    .ireq(write_ireq),
    .ienb(write_ienb),
    
    .irow(write_irow),
    .icolumn(write_icolumn),
    .ibank(write_ibank),
    .idata(iwrite_data),
    .ofin(write_fin),
    
    .DRAM_ADDR(DRAM_ADDR),
    .DRAM_BA(DRAM_BA),
    .DRAM_CAS_N(DRAM_CAS_N),
    .DRAM_CKE(DRAM_CKE),
    .DRAM_CLK(DRAM_CLK),
    .DRAM_CS_N(DRAM_CS_N),
    .DRAM_DQ(DRAM_DQ),
    .DRAM_LDQM(DRAM_LDQM),
    .DRAM_RAS_N(DRAM_RAS_N),
    .DRAM_UDQM(DRAM_UDQM),
    .DRAM_WE_N(DRAM_WE_N)
);

sdram_read sdram_read (
    .iclk(iclk),
    .ireset(ireset),
    
    .ireq(read_ireq),
    .ienb(read_ienb),
    
    .irow(read_irow),
    .icolumn(read_icolumn),
    .ibank(read_ibank),
    .odata(oread_data),
    .ofin(read_fin),
    
    .DRAM_ADDR(DRAM_ADDR),
    .DRAM_BA(DRAM_BA),
    .DRAM_CAS_N(DRAM_CAS_N),
    .DRAM_CKE(DRAM_CKE),
    .DRAM_CLK(DRAM_CLK),
    .DRAM_CS_N(DRAM_CS_N),
    .DRAM_DQ(DRAM_DQ),
    .DRAM_LDQM(DRAM_LDQM),
    .DRAM_RAS_N(DRAM_RAS_N),
    .DRAM_UDQM(DRAM_UDQM),
    .DRAM_WE_N(DRAM_WE_N)
);

endmodule
