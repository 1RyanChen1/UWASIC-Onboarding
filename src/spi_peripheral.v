module spi_peripheral (
    input clk , input rst_n, input COPI, input cs, input SCLK, 
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
reg [4:0] count = 0;
reg [15:0] data = 0;
reg [1:0] sync_sclk = 0,sync_ncs = 0,sync_COPI = 0; 
reg sclk_rise = 0,sclk_fall = 0,nsc_fall = 0, nsc_rise = 0;
reg prev_sclk = 0, prev_ncs = 0, prev_COPI = 0;


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
        sclk_rise <= 0;
      	sclk_fall <= 0;  
      	nsc_fall <= 0;
        nsc_rise <= 0;
    end else begin
        sync_ncs[0] <= cs;
        sync_ncs[1] <= sync_ncs[0];
        prev_ncs <= sync_ncs[1];
        sync_sclk[0] <= SCLK;
        sync_sclk[1] <= sync_sclk[0];
		prev_sclk <= sync_sclk[1];
        sync_COPI[0] <= COPI;
        sync_COPI[1] <= sync_COPI[0];
        prev_COPI <= sync_COPI[1];
        nsc_fall <= prev_ncs & !sync_ncs[1];
        nsc_rise <= !prev_ncs & sync_ncs[1];
        sclk_fall <= prev_sclk & !sync_sclk[1];
        sclk_rise <= !prev_sclk & sync_sclk[1];
        
        if (nsc_fall ) begin
            count <= 5'b0;
            data <= 16'd0;
        end else if (sclk_rise && count < 5'd16 && !prev_ncs) begin
            if (count == 5'd0) begin
                data[15] <= prev_COPI;
            end else if(data[15]) begin
                data[15-count] <= prev_COPI;
            end 
            count <= count + 1;
        end else if(nsc_rise && data[15] && data[14:8] <= 7'd4 && count == 5'd16) begin
            case (data[14:8])
                7'h00: en_reg_out_7_0 <= data[7:0];
                7'h01: en_reg_out_15_8 <= data[7:0];
                7'h02: en_reg_pwm_7_0 <= data[7:0];
                7'h03: en_reg_pwm_15_8 <= data[7:0];
                7'h04: pwm_duty_cycle <= data[7:0];
                default: ;
            endcase                     
        end

    end   
   
end
    
endmodule