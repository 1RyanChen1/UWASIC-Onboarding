module top_module ();
	reg clk=0;
    reg sclk=0;
	always #5 clk = ~clk; 
    always #20 sclk = ~sclk;// Create clock with period=10
	initial `probe_start;   // Start the timing diagram

	`probe(clk);        // Probe signal "clk"
    `probe(sclk);
	// A testbench
	reg in=1;
    wire sclk_rise;
	initial begin

		#10 in <= 0;
		#10 in <= 1;

		#150 $finish;            // Quit the simulation
	end

    test inst1 ( .clk(clk),.rst(in),.sclk(sclk),.sclk_rise(sclk_rise) );   // Sub-modules work too.
    `probe(sclk_rise);
endmodule

module test(input wire clk,input sclk, input wire rst, output wire sclk_rise);
    reg [1:0] sync_sclk = 2'd0;
	reg prev_sclk = 1'b0, rise_reg = 1'b0;
    always @(posedge clk or negedge rst ) begin
        if(!rst) begin
            sync_sclk <= 2'd0;
            prev_sclk <= 1'b0;
            rise_reg <= 1'b0;
        end else begin
            sync_sclk[1] <= sclk;
            sync_sclk[0] <= sync_sclk[1];
            prev_sclk <= sync_sclk[0];
            rise_reg <= (!prev_sclk & sync_sclk[0]) ? 1'b1 : 1'b0;
        end
	end
    assign sclk_rise = rise_reg;
    `probe(rst);	// Sub-modules can also have `probe()

    `probe(sync_sclk[1]);
    `probe(sync_sclk[0]);
    `probe(prev_sclk);
    `probe(sclk_rise);
endmodule

