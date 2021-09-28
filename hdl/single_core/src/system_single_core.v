`timescale 1 ns / 1 ps

`include "io.vh"

// MEM_SIZE = Number of 32 bit words (multiply by 4 to get byte count)
module system_single_core #(
    parameter MATRIX_TYPE_BITS      = 1,
    parameter MATRIX_COORD_BITS     = 8,
    parameter MATRIX_ELEMENT_BITS   = 32,
    
    parameter USE_MATRIX_INIT_FILE = 1,

    parameter FIRMWARE         = "firmware.hex",
    parameter MEM_SIZE         = 4096,

    parameter DIVIDE_ENABLED   = 0,
    parameter MULTIPLY_ENABLED = 1
) (
    input               clk,
    input               reset_n,

    output reg          LED,

    // UART
    output reg[7:0]     out_char,
    output reg          out_char_en,
    input wire          out_char_ready,

    input wire[MATRIX_TYPE_BITS-1:0]    matrix_type_in,
    input wire[MATRIX_COORD_BITS-1:0]   matrix_x_coord_in,
    input wire[MATRIX_COORD_BITS-1:0]   matrix_y_coord_in,
    input wire[MATRIX_ELEMENT_BITS-1:0] matrix_element_in,
    input wire                          message_in_valid,
    input wire                          message_in_available,
    output reg                          message_in_read,

    // Matrix output
    output reg[31:0]    out_matrix,
    output reg          out_matrix_en,
    output reg          out_matrix_end_row,
    output reg          out_matrix_end
);
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


   reg [15:0] led_cnt = {16{1'b0}};

   always @(posedge clk)
   begin
      led_cnt <= led_cnt - 1'b1;
    end
    
    assign led = led_cnt;

    wire [0:0]  trap_ila;
    
    assign trap_ila[0] = trap;


    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh(FIRMWARE, memory);

    reg [31:0] m_read_data;
    reg m_read_en;

    generate if (FAST_MEMORY) begin
        always @(posedge clk) begin
            mem_ready <= 1;
            
            if (reset_n == 0) begin
                LED <= 0;
            end

            message_in_read     <= 0;

            out_char_en             <= 0;
            out_matrix_en           <= 0;
            out_matrix_end_row      <= 0;
            out_matrix_end          <= 0;

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
                `CHAR_OUTPUT: begin
                    out_char_en     <= 1;
                    out_char        <= mem_la_wdata;
                end

                `LED_OUTPUT: begin
                    LED  <= mem_la_wdata[0];
                end

                `MATRIX_INIT_READ_OUTPUT: begin
                    message_in_read <= 1;
                end
                
                // Testbench outputs
                `MATRIX_END_ROW_OUTPUT: begin
                    out_matrix_end_row <= mem_la_wdata;
                end
                `MATRIX_END_OUTPUT: begin
                    out_matrix_end  <= mem_la_wdata;
                end
                `MATRIX_OUTPUT: begin
                    out_matrix_en   <= 1;
                    out_matrix      <= mem_la_wdata;
                end
              endcase
            end
            
            if (mem_la_read) begin
            case(mem_la_addr)
                `CHAR_OUTPUT_READY_INPUT: begin
                    mem_rdata   <= out_char_ready;
                end

                `MATRIX_INIT_TYPE_INPUT: begin
                    mem_rdata   <= matrix_type_in;
                end
                `MATRIX_INIT_X_COORD_INPUT: begin
                    mem_rdata   <= matrix_x_coord_in;
                end
                `MATRIX_INIT_Y_COORD_INPUT: begin
                    mem_rdata   <= matrix_y_coord_in;
                end
                `MATRIX_INIT_ELEMENT_INPUT: begin
                    mem_rdata   <= matrix_element_in;
                end
                `MATRIX_INIT_FROM_FILE_INPUT: begin
                    if (USE_MATRIX_INIT_FILE == 0) begin
                        mem_rdata   <= 0;
                    end else begin
                        mem_rdata   <= 1;
                    end
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

            out_char_en  <= 0;

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
                    out_char_en    <= 1;
                    out_char        <= mem_wdata;
                    mem_ready <= 1;
                end
            endcase
        end
    end endgenerate
endmodule
