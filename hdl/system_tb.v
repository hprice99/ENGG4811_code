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

    wire led1;
    wire[15:0] leds;
    
    reg sw = 0;
    
    integer switchCount = 0;
    
    always @(posedge clk) begin
        switchCount <= switchCount + 1;
        
        if (switchCount % 7 > 3) begin
            sw <= ~sw;
        end
    end

	system uut (
		.clk          (clk),
		.resetn       (resetn),
		.sw           (sw),
		.led          (leds),
		.RGB_LED      (led1),
		.trap         (trap),
		.out_byte_en  (out_byte_en),
		.out_byte     (out_byte)
	);

	always @(posedge clk) begin
		if (resetn && out_byte_en) begin
			$write("%c", out_byte);
			$fflush;
		end
		if (resetn && trap) begin
			$finish;
		end
	end
endmodule
