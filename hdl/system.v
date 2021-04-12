`timescale 1 ns / 1 ps

module system #(
	parameter USE_ILA = 1,
	parameter DIVIDE_ENABLED = 0,
	parameter MULTIPLY_ENABLED = 1
) (
	input            clk,
	input            resetn,
	input            sw,
	output wire[15:0] led,
	output reg       RGB_LED,
	output reg[7:0]  out_byte,
	output reg[0:0]  out_byte_en,
	output wire      trap
);
	// set this to 0 for better timing but less performance/MHz
	parameter FAST_MEMORY = 1;

	// 4096 32bit words = 16kB memory
	parameter MEM_SIZE = 4096;

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
		.resetn      (resetn      ),
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


   reg [15:0] led_cnt = {16{1'b0}};

   always @(posedge clk)
   begin
      led_cnt <= led_cnt - 1'b1;
    end
    
    assign led = led_cnt;


	// wire           trap;
	// reg [7:0] out_byte;
	// reg [0:0]      out_byte_en;
    wire [0:0]  trap_ila;
    
    assign trap_ila[0] = trap;

//    generate 
//        if (USE_ILA) begin
//            ila_0 inst_ila_0 (.clk(clk), .probe0(out_byte), .probe1(trap_ila), .probe2(out_byte_en));
//        end 
//    endgenerate


	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	reg [31:0] m_read_data;
	reg m_read_en;

	generate if (FAST_MEMORY) begin
		always @(posedge clk) begin
			mem_ready <= 1;
			out_byte_en[0] <= 0;
			mem_rdata <= memory[mem_la_addr >> 2];
			
			if (mem_la_write && (mem_la_addr >> 2) < MEM_SIZE) begin
				if (mem_la_wstrb[0]) memory[mem_la_addr >> 2][ 7: 0] <= mem_la_wdata[ 7: 0];
				if (mem_la_wstrb[1]) memory[mem_la_addr >> 2][15: 8] <= mem_la_wdata[15: 8];
				if (mem_la_wstrb[2]) memory[mem_la_addr >> 2][23:16] <= mem_la_wdata[23:16];
				if (mem_la_wstrb[3]) memory[mem_la_addr >> 2][31:24] <= mem_la_wdata[31:24];
			end
			else
			
			if (mem_la_write) begin
			case(mem_la_addr)
			     32'h1000_0000: begin
				    out_byte_en[0] <= 1;
				    out_byte <= mem_la_wdata;
				    end
				 32'h2000_0000: begin
				    RGB_LED <= mem_la_wdata;
				    end
		      endcase
			end
			
			if (mem_la_read) begin
			case(mem_la_addr)
			     32'h3000_0000: begin
				    mem_rdata <= sw;
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

			out_byte_en[0] <= 0;

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
					out_byte_en[0] <= 1;
					out_byte <= mem_wdata;
					mem_ready <= 1;
				end
			endcase
		end
	end endgenerate
endmodule
