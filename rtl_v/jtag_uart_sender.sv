// =============================================================================
// FILE: jtag_uart_sender.sv
// DATE: 17-Jan-2019
// AUTHOR: Sammy Carbajal
// =============================================================================
// PURPOSE: 
//   JTAG UART sender
// =============================================================================

module jtag_uart_sender (
  // Clock
  input 	clock,

  // Reset 
  input 	reset_n,

  // Avalon MM Interface
  output 	read, 
  output 	write, 
  output [2:0] 	address,
  output 	chipselect,
  output [3:0]  byteenable,
  output [31:0] writedata,
  input  [31:0] readdata,
  input         waitrequest,

  // Avalon ST Sink Interface
  input [1:0] av_sink_error,
  input [7:0] av_sink_data,
  input       av_sink_valid,
  output      av_sink_ready
);

enum logic [1:0] { WRITE_WAIT = 2'd0,
	           WRITE_CMP  = 2'd1,
	           READ_WAIT  = 2'd2,
	           READ_CMP   = 2'd3
 	         } state_ff, state_ns;

// State register
always_ff @(posedge clock, negedge reset_n)
  if (!reset_n)
    state_ff <= READ_WAIT;
  else 
    state_ff <= state_ns;

// Next state logic
always_comb
begin
  state_ns = state_ff;
  case (state_ff)
    READ_WAIT:  if(!waitrequest & readdata[31:16]!='d0)  
	           state_ns = READ_CMP;
    READ_CMP:   if(av_sink_valid) 
		   state_ns = WRITE_WAIT;
	        else	
		   state_ns = READ_WAIT;
    WRITE_WAIT: if(!waitrequest)  
	           state_ns = WRITE_CMP;
    WRITE_CMP:   state_ns = READ_WAIT;
    default: ;

  endcase
end

// Outputs
assign chipselect = 1'b1;
assign writedata = {24'd0, av_sink_data};
assign read  = (state_ff == READ_WAIT);
assign write = (state_ff == WRITE_WAIT);
assign address = write? 3'b000: 3'b100;
assign byteenable = write? 4'b0001: 4'b1100;
assign av_sink_ready =  (state_ff == WRITE_WAIT) & !waitrequest; 

endmodule
