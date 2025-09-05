module top_module ();
	reg clk=0;
	always #1 clk = ~clk;
    reg sclk = 0;// Create clock with period=2
	initial `probe_start;   // Start the timing diagram
	always #4 sclk = ~sclk;
	`probe(clk);        // Probe signal "clk"
	reg rst_n,COPI = 0,ncs;
	// A testbench
	reg in=0;
    wire [7:0] en_reg_out_7_0,en_reg_out_15_8,en_reg_pwm_7_0,en_reg_pwm_15_8,pwm_duty_cycle;
    `probe(sclk);
    `probe(COPI);
    `probe(ncs);
    `probe(rst_n);
    `probe(en_reg_out_7_0);
    `probe(en_reg_out_15_8); 
    `probe(en_reg_pwm_7_0);
    `probe(en_reg_pwm_15_8);  
    `probe(pwm_duty_cycle); 
	initial begin
		#8 rst_n <= 1;
		#8 rst_n <= 0;
		#12 rst_n <= 0;
        #12 rst_n <= 1;
		#8  ncs <= 1;
        #8  ncs <= 0;
        #8 COPI <= 0; // R/W = 0 (Read)

        #8 COPI <= 0; // Addr[6] = 0
        #8 COPI <= 0; // Addr[5] = 0
        #8 COPI <= 0; // Addr[4] = 0
        #8 COPI <= 0; // Addr[3] = 0
        #8 COPI <= 0; // Addr[2] = 0
        #4 COPI <= 1; // Addr[1] = 1
        #4 COPI <= 1; // Addr[0] = 1

        #4 COPI <= 1; // Data[7] = 1
        #4 COPI <= 0; // Data[6] = 0
        #4 COPI <= 1; // Data[5] = 1
        #4 COPI <= 0; // Data[4] = 0
        #4 COPI <= 1; // Data[3] = 1
        #4 COPI <= 0; // Data[2] = 0
        #4 COPI <= 1; // Data[1] = 1
        #4 COPI <= 1; // Data[0] = 1

        #4  ncs <= 1;
		#150 $finish;            // Quit the simulation
	end
	
    spi_peripheral inst1 ( .clk(clk),.SCLK(sclk),.cs(ncs),.COPI(COPI),.en_reg_out_7_0(en_reg_out_7_0),
                          .en_reg_out_15_8(en_reg_out_15_8),
                          .en_reg_pwm_7_0(en_reg_pwm_7_0),.en_reg_pwm_15_8(en_reg_pwm_15_8),.pwm_duty_cycle(pwm_duty_cycle) );   // Sub-modules work too.

endmodule

module spi_peripheral (
    input clk , input rst_n, input COPI, input cs, input SCLK, 
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
reg [4:0] count;
reg [15:0] data;
reg [1:0] sync_sclk,sync_ncs,sync_COPI; 
wire sclk_rise,sclk_fall,nsc_fall, nsc_rise;
reg prev_sclk, prev_ncs, prev_COPI;

assign    nsc_fall = prev_ncs & !sync_ncs[1];
assign    nsc_rise = !prev_ncs & sync_ncs[1];
assign    sclk_fall = prev_sclk & !sync_sclk[1];
assign    sclk_rise = !prev_sclk & sync_sclk[1];


always @(posedge clk or negedge rst_n)begin

    if(!rst_n)begin
        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <= 8'b0;
        en_reg_pwm_15_8 <= 8'b0;
        pwm_duty_cycle <= 8'b0;
        count <= 5'b0;
        sync_sclk<= 2'b0;
        sync_ncs<= 2'b0;
        sync_COPI<= 2'b0;
        data<= 16'b0;
        prev_COPI <= 0;
        prev_ncs <= 0;
        prev_sclk <= 0;
    end else begin
        sync_ncs[0] <= cs;
        sync_ncs[1] <= sync_ncs[0];
        prev_ncs <= sync_ncs[1];
        sync_sclk[0] <= SCLK;
        sync_sclk[1] <= sync_sclk[0];
        prev_ncs <= sync_sclk[1];
        sync_COPI[0] <= COPI;
        sync_COPI[1] <= sync_COPI[0];
        prev_COPI <= sync_COPI[1];
        
        if (nsc_fall) begin
            count <= 5'b0;
            data <= 16'd0;
        end else if (sclk_rise && count < 5'd16 && !prev_ncs) begin
            if (count == 5'd0) begin
                data[0] <= prev_COPI;
            end else if(data[0]) begin
                data[15-count] <= prev_COPI;
            end 
            count <= count + 1;
        end else if(nsc_rise && data[0] && data[7:1] <= 7'd4 && count == 5'd16) begin
            case (data[7:1])
                7'h00: en_reg_out_7_0 <= data[15:8];
                7'h01: en_reg_out_15_8 <= data[15:8];
                7'h02: en_reg_pwm_7_0 <= data[15:8];
                7'h03: en_reg_pwm_15_8 <= data[15:8];
                7'h04: pwm_duty_cycle <= data[15:8];
                default: ;
            endcase                     
        end

    end   
   
end
    `probe(SCLK);
    `probe(sync_sclk[0]);
    `probe(sync_sclk[1]);
    `probe(prev_sclk);
    `probe(sclk_rise);
    
    `probe(sync_ncs[1]);
    `probe(prev_ncs);
    `probe(nsc_fall);
    `probe(nsc_rise);
    `probe(data[15:8]);
    `probe(data[7:1]);
    `probe(sync_COPI[1]);
    `probe(COPI);
    `probe(count);
    `probe(data[0]);
endmodule

