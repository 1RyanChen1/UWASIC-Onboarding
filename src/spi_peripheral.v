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
reg [1:0] prevSCLK,prevCS,prevCOPI; 
wire sclk_rise,sclk_fall,nsc_fall, nsc_rise;

always @(*) begin
    nsc_fall = prevCS[0] & !prevCS[1];
    nsc_rise = !prevCS[0] & prevCS[1];
    sclk_fall = prevSCLK[0] & !prevSCLK[1];
    sclk_rise = !prevSCLK[0] & prevSCLK[1];
end

always @(posedge clk or negedge rst_n)begin

    if(!rst_n)begin
        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <= 8'b0;
        en_reg_pwm_15_8 <= 8'b0;
        pwm_duty_cycle <= 8'b0;
        count <= 5'b0;
    end else begin
        prevCS[0] <= cs;
        prevCS[1] <= prevCS[0];
        prevSCLK[0] <= SCLK;
        prevSCLK[1] <= prevSCLK[0];
        prevCOPI[0] <= COPI;
        prevCOPI[1] <= prevCOPI[0];
        if (nsc_fall) begin
            count <= 5'b0;
            data <= 16'd0;
        end else if (sclk_rise) begin
            if (count == 5'd16) begin
                count<=5'b0;
            end else begin
                count <= count + 1;
                data[count] = prevCOPI[1];
            end
        end else if(nsc_rise) begin
            if (data[0] && data[7:1] <= 7'd4 && count == 5'd16) begin
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
   
end
    
endmodule