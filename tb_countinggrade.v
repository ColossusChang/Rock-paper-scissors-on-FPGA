module tb_countinggrade;
    reg start_pulse;
	reg [2:0]left;
	reg [2:0]right;
	wire [2:0]a_score;
	wire [2:0]b_score;
	reg sw2;//serves as clear
    counting_grade UUT(start_pulse,left,right,a_score,b_score,sw2);
    initial begin
    #0 left=3'b000;right=3'b000;sw2=1;start_pulse=0;
    #10 sw2=0;
    #50 left=3'b001; right=3'b010;
    #50 left=3'b010;right=3'b001;
    #50 left=3'b001;right=3'b100;
    #50 left=3'b100;right=3'b100;
    #50 sw2=1;
    end
    always #25 start_pulse=~start_pulse; 
    initial #300 $stop;
endmodule
