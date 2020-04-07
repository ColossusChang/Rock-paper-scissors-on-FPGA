module tbpic;
    reg clk;
	reg [2:0]new_button_left;
	reg [2:0]new_button_right;
	reg ready_pulse;
	reg start_pulse;
	wire [7:0]row;
	wire [7:0]col_R;
	wire [7:0]col_G;
	reg [2:0]grade_left;
	reg [2:0]grade_right;
    pic UUT(clk,row,col_R,col_G,new_button_left,new_button_right,ready_pulse,start_pulse,grade_left,grade_right);
    initial begin
    #0 clk=0;new_button_left=3'b000;new_button_right=3'b000; ready_pulse=0;start_pulse=0;grade_left=3'b000;grade_right=3'b000;
    #8000000 ready_pulse=1;
    #8000000 start_pulse=1;new_button_left=3'b001;new_button_right=3'b010;
    #8000000 new_button_left=3'b100;new_button_right=3'b001;
    #8000000 new_button_left=3'b010;new_button_right=3'b100;
    #8000000 new_button_left=3'b000;new_button_right=3'b000;start_pulse=0;ready_pulse=0;grade_left=3'b011;
    #8000000 grade_left=3'b000;grade_right=3'b011;
    end
	always #10 clk=~clk;//20ns is 50MHz,1000Hz is 10^6 ns, 500Hz is 2*10^6 ns.  
	initial #56_000_000 $stop;
endmodule
