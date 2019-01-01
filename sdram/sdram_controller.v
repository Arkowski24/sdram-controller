module sdram_controller(
	input 		          		iclk,
    input 		          		ireset,
    
    input                       iwrite_req,
    input           [24:0]      iwrite_address,
    input           [15:0]      iwrite_data,
    output                      owrite_ack,
    
    input                       iread_req,
    input           [24:0]      iread_address,
    output          [15:0]      oread_data,
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
reg             read_ack    = 1'b0;
reg             write_ack   = 1'b0;
reg      [1:0]  mul_state   = 2'b00;

reg             init_reset  = 1'b0;
reg             write_reset = 1'b0;
reg             read_req    = 1'b0;
reg             data_ok     = 1'b0;

//SDRAM INITLIZE MODULE
wire            init_iclk;
wire            init_ireset;
wire            dram_ready;
wire    [12:0]  init_DRAM_ADDR;
wire	 [1:0]	init_DRAM_BA;
wire		    init_DRAM_CAS_N;
wire		    init_DRAM_CKE;
wire		    init_DRAM_CLK;
wire		    init_DRAM_CS_N;
wire    [15:0]	init_DRAM_DQ;
wire	        init_DRAM_LDQM;
wire		    init_DRAM_RAS_N;
wire	        init_DRAM_UDQM;
wire	        init_DRAM_WE_N;

//SDRAM WRITE MODULE
wire            write_iclk;
wire            write_ireset;
wire	[15:0]  write_idata;
wire    [12:0]  write_irow;
wire     [9:0]  write_icolumn;
wire     [1:0]  write_ibank;
wire            write_fin;
wire    [12:0]  write_DRAM_ADDR;
wire	 [1:0]	write_DRAM_BA;
wire		    write_DRAM_CAS_N;
wire		    write_DRAM_CKE;
wire		    write_DRAM_CLK;
wire		    write_DRAM_CS_N;
wire    [15:0]	write_DRAM_DQ;
wire	        write_DRAM_LDQM;
wire		    write_DRAM_RAS_N;
wire	        write_DRAM_UDQM;
wire	        write_DRAM_WE_N;

//SDRAM READ MODULE
wire            read_iclk;
wire            read_ireq;
wire    [12:0]  read_irow;
wire     [9:0]  read_icolumn;
wire     [1:0]  read_ibank;
wire	[15:0]  read_odata;
wire            read_fin;

wire    [12:0]  read_DRAM_ADDR;
wire	 [1:0]	read_DRAM_BA;
wire		    read_DRAM_CAS_N;
wire		    read_DRAM_CKE;
wire		    read_DRAM_CLK;
wire		    read_DRAM_CS_N;
wire    [15:0]	read_DRAM_DQ;
wire	        read_DRAM_LDQM;
wire		    read_DRAM_RAS_N;
wire	        read_DRAM_UDQM;
wire	        read_DRAM_WE_N;


wire            read_chosen;
wire            write_chosen;
//=======================================================
//  Structural coding
//=======================================================
//TO DO -- Usunąć to i zastąpić tristate'ami. 
assign DRAM_ADDR        = (mul_state == 2'b10) ? read_DRAM_ADDR     : ((mul_state == 2'b01) ? write_DRAM_ADDR   : init_DRAM_ADDR);
assign DRAM_BA          = (mul_state == 2'b10) ? read_DRAM_BA       : ((mul_state == 2'b01) ? write_DRAM_BA     : init_DRAM_BA);
assign DRAM_CAS_N       = (mul_state == 2'b10) ? read_DRAM_CAS_N    : ((mul_state == 2'b01) ? write_DRAM_CAS_N  : init_DRAM_CAS_N);
assign DRAM_CKE         = (mul_state == 2'b10) ? read_DRAM_CKE      : ((mul_state == 2'b01) ? write_DRAM_CKE    : init_DRAM_CKE);
assign DRAM_CLK         = (mul_state == 2'b10) ? read_DRAM_CLK      : ((mul_state == 2'b01) ? write_DRAM_CLK    : init_DRAM_CLK);
assign DRAM_CS_N        = (mul_state == 2'b10) ? read_DRAM_CS_N     : ((mul_state == 2'b01) ? write_DRAM_CS_N   : init_DRAM_CS_N);
assign DRAM_DQ          = data_ok? ((read_chosen) ? read_DRAM_DQ : ((write_chosen) ? write_DRAM_DQ : init_DRAM_DQ)) : 16'bz;
assign DRAM_LDQM        = (mul_state == 2'b10) ? read_DRAM_LDQM     : ((mul_state == 2'b01) ? write_DRAM_LDQM   : init_DRAM_LDQM);
assign DRAM_RAS_N       = (mul_state == 2'b10) ? read_DRAM_RAS_N    : ((mul_state == 2'b01) ? write_DRAM_RAS_N  : init_DRAM_RAS_N);
assign DRAM_UDQM        = (mul_state == 2'b10) ? read_DRAM_UDQM     : ((mul_state == 2'b01) ? write_DRAM_UDQM   : init_DRAM_UDQM);
assign DRAM_WE_N        = (mul_state == 2'b10) ? read_DRAM_WE_N     : ((mul_state == 2'b01) ? write_DRAM_WE_N   : init_DRAM_WE_N);

assign init_iclk        = iclk;
assign write_iclk       = iclk;
assign read_iclk        = iclk;

assign init_ireset  = init_reset;
assign write_ireset = write_reset;
assign read_ireq    = read_req;

assign {write_ibank, write_irow, write_icolumn} = iwrite_address;
assign {read_ibank, read_irow, read_icolumn}    = iread_address;
assign write_idata                              = iwrite_data;
assign read_odata                               = oread_data;

assign owrite_ack                               = write_ack;
assign oread_ack                                = read_ack;
assign oread_data                               = read_odata;

assign write_chosen = mul_state == 2'b01;
assign read_chosen  = mul_state == 2'b10;

always @(posedge iclk or posedge ireset)
begin
    if(ireset)
        state       <= 9'b000000001;
    else
        case(state)
            //Init States
            9'b000000001:
                state           <= 9'b000000010;
            9'b000000010:
                if(dram_ready)
                    state       <= 9'b000000100;
                else
                    state       <= 9'b000000010;
            //Idle State
            9'b000000100:
                if(iwrite_req)
                    state       <= 9'b000001000;
                else if(iread_req)
                    state       <= 9'b001000000;
                else
                    state       <= 9'b000000100;
            //Write States
            9'b000001000:
                state           <= 9'b000010000;    
            9'b000010000:
                if(write_fin)
                    state       <= 9'b000100000;
                else
                    state       <= 9'b000010000;
            9'b000100000:
                state           <= 9'b000000100;
            //Read States        `
            9'b001000000:
                state           <= 9'b010000000;
            9'b010000000:
                if(read_fin)
                    state       <= 9'b100000000;
                else
                    state       <= 9'b010000000;
            9'b100000000:
                state           <= 9'b000000100;
        endcase
end

always @(state)
begin
    case(state)
        9'b000000001:
        begin            
            init_reset      <= 1'b1;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b00;
            data_ok         <= 1'b0;
        end
        9'b000000010:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b00;
            data_ok         <= 1'b0;
        end
        9'b000000100:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b00;
            data_ok         <= 1'b0;
        end
        9'b000001000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b1;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b01;
            data_ok         <= 1'b1;
        end
        9'b000010000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b01;
            data_ok         <= 1'b1;
        end
        9'b000100000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b1;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b01;
            data_ok         <= 1'b0;
        end
        9'b001000000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b1;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b10;
            data_ok         <= 1'b1;
        end
        9'b010000000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b0;
            
            mul_state       <= 2'b10;
            data_ok         <= 1'b1;
        end
        9'b100000000:
        begin            
            init_reset      <= 1'b0;
            write_reset     <= 1'b0;
            read_req        <= 1'b0;
            
            write_ack       <= 1'b0;
            read_ack        <= 1'b1;
            
            mul_state       <= 2'b10;
            data_ok         <= 1'b0;
        end
    endcase
end

sdram_initalize sdram_init (
    .iclk(init_iclk),
    .ireset(init_ireset),
    .odram_ready(dram_ready),
    .DRAM_ADDR(init_DRAM_ADDR),
    .DRAM_BA(init_DRAM_BA),
    .DRAM_CAS_N(init_DRAM_CAS_N),
    .DRAM_CKE(init_DRAM_CKE),
    .DRAM_CLK(init_DRAM_CLK),
    .DRAM_CS_N(init_DRAM_CS_N),
    .DRAM_DQ(init_DRAM_DQ),
    .DRAM_LDQM(init_DRAM_LDQM),
    .DRAM_RAS_N(init_DRAM_RAS_N),
    .DRAM_UDQM(init_DRAM_UDQM),
    .DRAM_WE_N(init_DRAM_WE_N)
);

sdram_write sdram_write (
    .iclk(write_iclk),
    .ireset(write_ireset),
    .idata(write_idata),
    .irow(write_irow),
    .icolumn(write_icolumn),
    .ibank(write_ibank),
    .owrite_fin(write_fin),
    
    .DRAM_ADDR(write_DRAM_ADDR),
    .DRAM_BA(write_DRAM_BA),
    .DRAM_CAS_N(write_DRAM_CAS_N),
    .DRAM_CKE(write_DRAM_CKE),
    .DRAM_CLK(write_DRAM_CLK),
    .DRAM_CS_N(write_DRAM_CS_N),
    .DRAM_DQ(write_DRAM_DQ),
    .DRAM_LDQM(write_DRAM_LDQM),
    .DRAM_RAS_N(write_DRAM_RAS_N),
    .DRAM_UDQM(write_DRAM_UDQM),
    .DRAM_WE_N(write_DRAM_WE_N)
);

sdram_read sdram_read (
    .iclk(read_iclk),
    .ireq(read_ireq),
    .ienb(read_ienb),
    
    .irow(read_irow),
    .icolumn(read_icolumn),
    .ibank(read_ibank),
    .odata(read_odata),
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
