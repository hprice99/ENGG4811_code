`timescale 1 ns / 1 ps

// MEM_SIZE = Number of 32 bit words (multiply by 4 to get byte count)
module system #(
    parameter NETWORK_ROWS      = 2,
    parameter NETWORK_COLS      = 2,
    parameter NETWORK_NODES     = 4,
    parameter COORD_BITS        = 1,
    
    parameter X_COORD           = 0,
    parameter Y_COORD           = 0,
    parameter NODE_NUMBER       = 0,     

	parameter DIVIDE_ENABLED   = 0,
	parameter MULTIPLY_ENABLED = 1,
	parameter FIRMWARE         = "firmware.hex",
	parameter MEM_SIZE         = 4096
) (
	input              clk,
	input              reset_n,
	
	input              switch,
	output reg[NETWORK_NODES-1:0]  LED,
	
	output reg[7:0]    out_byte,
	output reg[0:0]    out_byte_en,
	
	output reg[COORD_BITS-1:0] x_coord_out,
	output reg                 x_coord_out_valid,
	
	output reg[COORD_BITS-1:0] y_coord_out,
	output reg                 y_coord_out_valid,
	
    output reg[31:0]    message_out,
    output reg          message_out_valid,
    
    output reg          packet_out_complete,
    
    input wire          message_out_ready,
    
    input wire[31:0]    message_in,
    input wire          message_in_valid,
    input wire          message_in_available,
    output reg          message_in_read,
    
	output wire        trap
);
    // Import memory-mapped IO addresses
    `include "io.vh"

	// set this to 0 for better timing but less performance/MHz
	parameter FAST_MEMORY = 1;

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;

	wire mem_la_read;
	wire mem_la_write;
	wire [31:0] mem_la_addr;
	wire [31:0] mem_la_wdata;
	wire [3:0] mem_la_wstrb;

	picorv32 #(
	   .ENABLE_MUL (MULTIPLY_ENABLED),
	   .ENABLE_DIV (DIVIDE_ENABLED)
	) picorv32_core (
		.clk         (clk         ),
		.resetn      (reset_n     ),
		.trap        (trap        ),
		.mem_valid   (mem_valid   ),
		.mem_instr   (mem_instr   ),
		.mem_ready   (mem_ready   ),
		.mem_addr    (mem_addr    ),
		.mem_wdata   (mem_wdata   ),
		.mem_wstrb   (mem_wstrb   ),
		.mem_rdata   (mem_rdata   ),
		.mem_la_read (mem_la_read ),
		.mem_la_write(mem_la_write),
		.mem_la_addr (mem_la_addr ),
		.mem_la_wdata(mem_la_wdata),
		.mem_la_wstrb(mem_la_wstrb)
	);

    wire [0:0]  trap_ila;
    
    assign trap_ila[0] = trap;

	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh(FIRMWARE, memory);

	reg [31:0] m_read_data;
	reg m_read_en;

	generate if (FAST_MEMORY) begin
		always @(posedge clk) begin
		    if (reset_n == 0) begin
		      LED <= 0;
		    end
            out_byte_en         <= 0;
            
            x_coord_out_valid   <= 0;
            y_coord_out_valid   <= 0;
            message_out_valid   <= 0;
            packet_out_complete <= 0;   
            
            message_in_read     <= 0;
            
			mem_ready    <= 1;

			mem_rdata <= memory[mem_la_addr >> 2];
			
			if (mem_la_write && (mem_la_addr >> 2) < MEM_SIZE) begin
				if (mem_la_wstrb[0]) memory[mem_la_addr >> 2][ 7: 0] <= mem_la_wdata[ 7: 0];
				if (mem_la_wstrb[1]) memory[mem_la_addr >> 2][15: 8] <= mem_la_wdata[15: 8];
				if (mem_la_wstrb[2]) memory[mem_la_addr >> 2][23:16] <= mem_la_wdata[23:16];
				if (mem_la_wstrb[3]) memory[mem_la_addr >> 2][31:24] <= mem_la_wdata[31:24];
			end
			else
			
			// Output
			if (mem_la_write) begin
			case(mem_la_addr)
			    `CHAR_OUTPUT: begin
			            out_byte_en[0]  <= 1;
				        out_byte        <= mem_la_wdata;
				    end
				`X_COORD_OUTPUT: begin
				        x_coord_out_valid   <= 1;
				        x_coord_out         <= mem_la_wdata;
				    end
				`Y_COORD_OUTPUT: begin
				        y_coord_out_valid   <= 1;
				        y_coord_out         <= mem_la_wdata;
				    end
				`MESSAGE_OUTPUT: begin
				        message_out_valid   <= 1;
				        message_out         <= mem_la_wdata;
				    end
				`PACKET_COMPLETE_OUTPUT: begin
				        packet_out_complete <= 1;
				    end
                `LED_0_OUTPUT: begin
				        LED[0]  <= mem_la_wdata[0];
				    end
				`LED_1_OUTPUT: begin
				        LED[1]  <= mem_la_wdata[0];
				    end
				`LED_2_OUTPUT: begin
				        LED[2]  <= mem_la_wdata[0];
				    end
				`LED_3_OUTPUT: begin
				        LED[3]  <= mem_la_wdata[0];
				    end
		      endcase
			end
	   
	       // Input
			if (mem_la_read) begin
			case(mem_la_addr)
			     `SWITCH_INPUT: begin
				        mem_rdata   <= switch;
				    end
				 `MESSAGE_OUT_READY_INPUT: begin
				        mem_rdata   <= message_out_ready;
				    end
                `MESSAGE_IN_AVAILABLE_INPUT: begin
				        mem_rdata   <= message_in_available;
				    end
				 `MESSAGE_VALID_INPUT: begin
				        mem_rdata   <= message_in_valid;
				    end   
				 `MESSAGE_INPUT: begin
				        mem_rdata           <= message_in;
				        message_in_read     <= 1;
				    end   
				  `X_COORD_INPUT: begin
				        mem_rdata           <= X_COORD;
				    end
				  `Y_COORD_INPUT: begin
				        mem_rdata           <= Y_COORD;
				    end
				  `NODE_NUMBER_INPUT: begin
				        mem_rdata           <= NODE_NUMBER;
				    end
		      endcase
			end
		end
	end else begin
		always @(posedge clk) begin
			m_read_en <= 0;
			mem_ready <= mem_valid && !mem_ready && m_read_en;

			m_read_data <= memory[mem_addr >> 2];
			mem_rdata <= m_read_data;

			(* parallel_case *)
			case (1)
				mem_valid && !mem_ready && !mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					m_read_en <= 1;
				end
				mem_valid && !mem_ready && |mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
					if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
					if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
					mem_ready <= 1;
				end
				mem_valid && !mem_ready && |mem_wstrb && mem_addr == 32'h1000_0000: begin
					mem_ready <= 1;
				end
			endcase
		end
	end endgenerate
endmodule
