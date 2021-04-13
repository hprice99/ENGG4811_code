`timescale 1 ns / 1 ps

module system_tb;
	reg clk = 1;
	always #5 clk = ~clk;

	reg resetn = 0;
	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("system.vcd");
			$dumpvars(0, system_tb);
		end
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	wire trap;
	wire [7:0] out_byte;
	wire out_byte_en;
	
	wire [7:0] out_matrix;
	wire out_matrix_en;
	wire out_matrix_end_row;
	wire out_matrix_end;

    wire led1;
    wire[15:0] leds;
    
    reg sw = 0;
    integer switchCount = 0;
    
    always @(posedge clk) begin
        switchCount <= switchCount + 1;
        
        // Pseudo-randomly change the switch state
        if (switchCount % 7 > 3) begin
            sw <= ~sw;
        end
    end

	system uut (
		.clk                  (clk),
		.resetn               (resetn),
		.sw                   (sw),
		.led                  (leds),
		.RGB_LED              (led1),
		.trap                 (trap),
		.out_byte_en          (out_byte_en),
		.out_byte             (out_byte),
		.out_matrix_en        (out_matrix_en),
		.out_matrix           (out_matrix),
		.out_matrix_end_row   (out_matrix_end_row),
		.out_matrix_end       (out_matrix_end)
	);

	always @(posedge clk) begin
		if (resetn && out_byte_en) begin
			$write("%c", out_byte);
			$fflush;
		end
		
		if (resetn && out_matrix_en) begin
			$write("%d", out_matrix);
			$fflush;
		end
		
		if (resetn && out_matrix_end_row) begin
			$write(" ; \n");
			$fflush;
		end
		
		if (resetn && out_matrix_end) begin
			$write("\n\n");
			$fflush;
		end
		
		/*
		if (resetn && trap) begin
			$finish;
		end
		*/
	end
endmodule
