module game(rst,clk,row,col_R,col_G,btn_left,btn_right,ready,start,DIG,Y,beep,one_more,LCD_EN,RS,RW,DB,sw7);
	input clk;//系统时钟
	input rst;//复位
	input  [2:0]btn_left;//甲出拳的三个按钮，实际对应BTN[5]-BTN[7]
	input  [2:0]btn_right;//乙出拳的三个按钮，实际对应BTN[0]-BTN[2]
	output [7:0]row;//点阵输出的行
	output [7:0]col_R;//双色点阵红色部分，乙的显示为红色
	output [7:0]col_G;//双色点阵绿色部分，甲的显示为绿色
	input ready,start;//裁判使用按键，按键表示为BTN[3],BTN[4]
	wire ready_pulse;
	wire start_pulse;
	wire [2:0]key_pulse_left;//消抖且稳定后的甲的输入状态
	wire [2:0]key_pulse_right;//消抖且稳定后的乙的输入状态
	wire [2:0]g_l;//甲的分数
	wire [2:0]g_r;//乙的分数
	output [7:0]DIG;//数码管的具体位置
	output [7:0]Y;//每个数码管亮的管脚
	output beep;//蜂鸣器
   reg[2:0] left;
   reg[2:0] right;
	reg o_ready=1'b0;
	reg o_start=1'b0;//对甲、乙、准备、开始按键的处理临时存储变量
	input one_more;//一盘游戏后再来一盘
	reg [14:0] divide=15'b000000000000000;//分频设定
	reg clk_out=1'b0;//输出的分频
	input sw7;//五局三胜后再来一局
	output wire LCD_EN;		//使能引脚
	output wire RS;
	output wire RW;		//数据命令、读写控制
	output [7:0] DB;	//读写信息端
	wire [2:0]round;

always@(posedge clk)
begin
	if(divide>=15'b110000110101000)//25000
	begin
		divide<=15'b000000000000000;
		clk_out<=clk_out+1;//分频频率为1000Hz，提供给数码管使用
	end
	else
		 divide<=divide+1;
end

	song sing(clk,beep);//无限循环播放《友谊地久天长》
	pic a(clk,row,col_R,col_G,left,right,o_ready,o_start,g_l,g_r);//点阵动画
	grade b(rst,DIG,Y,g_l,g_r,round,clk_out);//数码管显示分数
	counting_grade p(start_pulse,left,right,g_l,g_r,sw7,round);//计算分数
	LCD1602 q(clk_out, rst,g_l,g_r, LCD_EN, RS, RW, DB);//LCD1602显示分数
/*******************依次进行按键消抖*8****************/
	debounce u0 (
				.clk(clk),
				.i_key(btn_left[0]),
				.o_key(key_pulse_left[0])
				);
	debounce u1 (
				.clk(clk),
				.i_key(btn_left[1]),
				.o_key(key_pulse_left[1])
				);
	debounce u2 (
				.clk(clk),
				.i_key(btn_left[2]),
				.o_key(key_pulse_left[2])
				);
				
	debounce u5 (
				.clk(clk),
				.i_key(btn_right[0]),
				.o_key(key_pulse_right[0])
				);
	debounce u4 (
				.clk(clk),
				.i_key(start),
				.o_key(start_pulse)
				);
	debounce u6 (
				.clk(clk),
				.i_key(btn_right[1]),
				.o_key(key_pulse_right[1])
				);
	debounce u7 (
				.clk(clk),
				.i_key(btn_right[2]),
				.o_key(key_pulse_right[2])
				);
	debounce u3 (
				.clk(clk),
				.i_key(ready),
				.o_key(ready_pulse)
				);
	always @ (posedge clk)
		begin
			if(key_pulse_left[0]==1)
				left = 3'b001;
			else if(key_pulse_left[1]==1)
				left = 3'b010;
			else if(key_pulse_left[2]==1)
				left = 3'b100;
		end
//对甲的出拳情况进行处理，保证甲点击按钮后状态稳定为1
	always @ (posedge clk)
		begin
			if(key_pulse_right[0]==1)
				right <= 3'b001;
			else if	(key_pulse_right[1]==1)
				right <= 3'b010;
			else if	(key_pulse_right[2]==1)
				right <= 3'b100;
	
		end
//对乙的出拳情况进行处理，保证乙点击按钮后状态稳定为1
	always @ (posedge clk_out)
		begin
			if(ready_pulse==1)
				o_ready <= 1'b1;	
			if(start_pulse==1)
				o_start <= 1'b1;	
			if(one_more==1)
				begin o_ready<=1'b0;o_start<=1'b0;end
		end	
//对裁判按键进行处理，设置每一盘游戏玩完后的简单初始。
endmodule

/********************计分模块*******************/
module counting_grade(start_pulse,left,right,a_score,b_score,sw2,round);
	input start_pulse;//start
	input [2:0]left;
	input [2:0]right;
	output reg [2:0]a_score;
	output reg [2:0]b_score;
	reg flag=1'b0;
	input sw2;
	output reg[2:0]round;
	always@(posedge start_pulse)
	begin
	flag=1;//flag是设置的标志值，当flag为1时则表明可以进行计分，计分结束后flag变为0，则不能继续计分
	case(sw2)
	1'b0:
		begin
		if(flag==1) 
			begin
				case({left,right})//a is left's grade;b is right's grade
					6'b100001:begin a_score<=a_score+1;flag=1'b0;round=round+1;end
					6'b100010:begin b_score<=b_score+1;flag=1'b0;round=round+1;end
					6'b010100:begin a_score<=a_score+1;flag=1'b0;round=round+1;end
					6'b010001:begin b_score<=b_score+1;flag=1'b0;round=round+1;end
					6'b001010:begin a_score<=a_score+1;flag=1'b0;round=round+1;end
					6'b001100:begin b_score<=b_score+1;flag=1'b0;round=round+1;end
					6'b001001:begin a_score<=a_score;b_score<=b_score;flag=1'b0;round=round+1;end
					6'b010010:begin a_score<=a_score;b_score<=b_score;flag=1'b0;round=round+1;end
					6'b100100:begin a_score<=a_score;b_score<=b_score;flag=1'b0;round=round+1;end
					default:;
					endcase
			end
		end
	1'b1:
		begin
			a_score<=0;
			b_score<=0;
			flag=1;
			round=0;//进行分数清零，开始再来一局
		end
	endcase
	end
endmodule
/***********点阵模块****************/
module pic(clk,row,col_R,col_G,new_button_left,new_button_right,ready_pulse,start_pulse,grade_left,grade_right);
	input clk;
	input [2:0]new_button_left;
	input [2:0]new_button_right;
	input ready_pulse;
	input start_pulse;
	output reg [7:0]row;
	output reg [7:0]col_R;
	output reg [7:0]col_G;
	reg [2:0]judge = 3'b000;
	reg [15:0] count=16'b0000000000000000;
	input [2:0]grade_left;
	input [2:0]grade_right;	
	
	always @(posedge clk)
	begin
	if(count>=16'b1100001101010000)//分频得到500Hz 8行需要400Hz以上的频率才能看到
	begin
	count<=16'b0000000000000000;
	judge=judge+1;
	end
	else
		count<=count+1;
	end
	
	always @(posedge clk)
	
	case({start_pulse,ready_pulse})
	2'b00:begin
			case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b01000010;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b001: begin
					row = 8'b10111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100111;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b010: begin
					row = 8'b11011111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100111;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00011000;		//row为0触发 col为1触发从右往左读
					end
				3'b011: begin
					row = 8'b11101111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b01000010;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00011000;		//row为0触发 col为1触发从右往左读
					end
				3'b100: begin
					row = 8'b11110111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00100100;		//row为0触发 col为1触发从右往左读
					end
				3'b101: begin	
					row = 8'b11111011;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100111;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b110: begin
					row = 8'b11111101;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100111;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end	
				3'b111: begin
					row = 8'b11111110;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100111;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				default:;
				endcase
			end
		2'b01:begin
		case(judge)
			3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b001: begin
					row = 8'b10111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b010: begin
					row = 8'b11011111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b011: begin
					row = 8'b11101111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b100: begin
					row = 8'b11110111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b101: begin
					row = 8'b11111011;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b110: begin
					row = 8'b11111101;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b111: begin
					row = 8'b11111110;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				default:;
				endcase
			end
	
		2'b11:
		begin
		case({new_button_left,new_button_right})
			6'b001001:begin//ʯͷʯͷ
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b001: begin
					row = 8'b10111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b010: begin
					row = 8'b11011111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b01000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000010;		//row为0触发 col为1触发从右往左读
					end
				3'b011: begin
					row = 8'b11101111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000111;		//row为0触发 col为1触发从右往左读
					end
				3'b100: begin
					row = 8'b11110111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b11100000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000111;		//row为0触发 col为1触发从右往左读
					end
				3'b101: begin
					row = 8'b11111011;		//row为0触发 col为1触发从右往左读
					col_R = 8'b01000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000010;		//row为0触发 col为1触发从右往左读
					end
				3'b110: begin
					row = 8'b11111101;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				3'b111: begin
					row = 8'b11111110;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;		//row为0触发 col为1触发从右往左读
					col_G = 8'b00000000;		//row为0触发 col为1触发从右往左读
					end
				default: ;
				endcase
			end
			6'b010001:begin//石头石头
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b01000000;
					col_G = 8'b00000100;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11100000;
					col_G = 8'b00000011;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11100000;
					col_G = 8'b00000011;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b01000000;
					col_G = 8'b00000100;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b100001:begin//布石头
				case(judge)
				3'b000: begin
					row = 8'b01111111;		
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b01000000;
					col_G = 8'b00000111;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b01000000;
					col_G = 8'b00000111;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b001010:begin//石头剪刀
				case(judge)
				3'b000: begin
					row = 8'b01111111;		
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b00100000;
					col_G = 8'b00000010;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11000000;
					col_G = 8'b00000111;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11000000;
					col_G = 8'b00000111;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b00100000;
					col_G = 8'b00000010;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b010010:begin//剪刀剪刀
				case(judge)
				3'b000: begin
					row = 8'b01111111;		
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b00100000;
					col_G = 8'b00000100;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11000000;
					col_G = 8'b00000011;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11000000;
					col_G = 8'b00000011;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b00100000;
					col_G = 8'b00000100;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b100010:begin//布剪刀
				case(judge)
				3'b000: begin
					row = 8'b01111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b00100000;
					col_G = 8'b00000111;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11000000;
					col_G = 8'b00000111;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11000000;
					col_G = 8'b00000111;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b00100000;
					col_G = 8'b00000111;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b001100:begin//石头布
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b11100000;
					col_G = 8'b00000010;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b11100000;
					col_G = 8'b00000010;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b010100:begin//剪刀布
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b11100000;
					col_G = 8'b00000100;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11100000;
					col_G = 8'b00000011;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11100000;
					col_G = 8'b00000011;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b11100000;
					col_G = 8'b00000100;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end
			6'b100100:begin//石头石头
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b11100000;
					col_G = 8'b00000111;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00000000;
					end
				default: ;
				endcase
			end			
		endcase
		begin
			if(grade_left>=3)
			//判断得分如果有超过3分则说明有人已经赢了，输出判断胜负的点阵显示
			//甲赢了则输出点阵图案：红色的甲
			begin
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//row为0触发 col为1触发从右往左读
					col_R = 8'b00000000;
					col_G = 8'b01111110;
					end
				3'b001: begin
					row = 8'b10111111;
					col_R = 8'b00000000;
					col_G = 8'b01011010;
					end
				3'b010: begin
					row = 8'b11011111;
					col_R = 8'b00000000;
					col_G = 8'b01111110;
					end
				3'b011: begin
					row = 8'b11101111;
					col_R = 8'b00000000;
					col_G = 8'b01011010;
					end
				3'b100: begin
					row = 8'b11110111;
					col_R = 8'b00000000;
					col_G = 8'b01111110;
					end
				3'b101: begin
					row = 8'b11111011;
					col_R = 8'b00000000;
					col_G = 8'b00011000;
					end
				3'b110: begin
					row = 8'b11111101;
					col_R = 8'b00000000;
					col_G = 8'b00011000;
					end
				3'b111: begin
					row = 8'b11111110;
					col_R = 8'b00000000;
					col_G = 8'b00011000;
					end
				default:;
				endcase end
			else if(grade_right>=3)begin
			//乙赢了则输出绿色的乙
				case(judge)
				3'b000: begin
					row = 8'b01111111;		//判断得分如果有超过3分则说明有人已经赢了，输出判断胜负的点阵显示
					col_G = 8'b00000000;
					col_R = 8'b00000000;
					end
				3'b001: begin
					row = 8'b10111111;
					col_G = 8'b00000000;
					col_R = 8'b01111110;
					end
				3'b010: begin
					row = 8'b11011111;
					col_G = 8'b00000000;
					col_R = 8'b00100000;
					end
				3'b011: begin
					row = 8'b11101111;
					col_G = 8'b00000000;
					col_R = 8'b00010000;
					end
				3'b100: begin
					row = 8'b11110111;
					col_G = 8'b00000000;
					col_R = 8'b00001000;
					end
				3'b101: begin
					row = 8'b11111011;
					col_G = 8'b00000000;
					col_R = 8'b00000100;
					end
				3'b110: begin
					row = 8'b11111101;
					col_G = 8'b00000000;
					col_R = 8'b01000010;
					end
				3'b111: begin
					row = 8'b11111110;
					col_G = 8'b00000000;
					col_R = 8'b01111110;
					end
				default:;
				endcase
			end
		end
		end
		endcase
endmodule

/************消抖模块*************/
module debounce
(    input  clk, 
     input  i_key,
     output  o_key);
reg r_key; reg r_key_buf1, r_key_buf2;
reg clk_100;
reg [17:0] divide;

assign o_key = r_key;
always@(posedge clk)
begin
	if(divide==18'b111101000010010000)//250000
	begin
		divide<=18'b000000000000000000;
		clk_100<=~clk_100;//分频得到100Hz
	end
	else
		divide<=divide+1;
	
end
always@(posedge clk_100)//消抖部分要在100Hz下完成
begin
    r_key_buf1 <= i_key;//进行一次延时
    r_key_buf2 <= r_key_buf1;//进行两次延时
    if((r_key_buf1~^r_key_buf2) == 1'b1) 	
            r_key <= r_key_buf2;
    else   
            r_key<=0;
end
endmodule

/**************分数显示模块******************/
module grade (rst,DIG,Y,grade_left,grade_right,round,clkout);
	input rst; wire rst;
	input clkout;
	output [7:0] DIG;	wire [7:0] DIG;//显示哪一个数码管亮
	output [7:0] Y;	wire [7:0] Y;//显示数码管的哪个管脚亮
	input [2:0]grade_left;
	input [2:0]grade_right;
	reg [31:0]cnt;
	reg [2:0]place=3'b000; 
	reg [6:0] Y_r=7'b0000000;
	reg [7:0] DIG_r;  
	parameter  period= 100000;
	assign Y = {1'b1,(~Y_r[6:0])};
	assign DIG =~DIG_r;

	input [2:0]round;

 always @(posedge clkout)          
        place = place + 1; 
     
always @(place)         //place是亮的数码管的位置
     begin 
     case (place)
        3'b000 : DIG_r <= 8'b0000_0001;
		  3'b011 : DIG_r <= 8'B0000_1000;
        3'b111 : DIG_r <= 8'b1000_0000;    
        default :DIG_r <= 8'b0000_0000;      
    endcase
    end
always @ ({grade_left, grade_right}) //当甲乙分数出现变化时，数码管才会变
    begin 
	 case (place)
	  3'b000:
		  case (grade_right)
				3'b000: Y_r = 7'b1000000; // 0   从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b001: Y_r = 7'b1111001; // 1	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b010: Y_r = 7'b0100100; // 2	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b011: Y_r = 7'b0110000; // 3	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b100: Y_r = 7'b0011001; // 4	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b101: Y_r = 7'b0010010; // 5	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b110: Y_r = 7'b0000010; // 6	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b111: Y_r = 7'b0000001; // 7	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
		 endcase
	 3'b011:
		case(round)
			3'b000: Y_r = 7'b1000000; // 0	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b001: Y_r = 7'b1111001; // 1	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b010: Y_r = 7'b0100100; // 2	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b011: Y_r = 7'b0110000; // 3	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b100: Y_r = 7'b0011001; // 4	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b101: Y_r = 7'b0010010; // 5	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b110: Y_r = 7'b0000010; // 6	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
			3'b111: Y_r = 7'b1111000; // 7	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序		
			default: Y_r = 7'b0000000;
		 endcase
	 3'b111:
		 case (grade_left)
				3'b000: Y_r = 7'b1000000; // 0	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b001: Y_r = 7'b1111001; // 1	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b010: Y_r = 7'b0100100; // 2	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				3'b011: Y_r = 7'b0110000; // 3	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b100: Y_r = 7'b0011001; // 4	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b101: Y_r = 7'b0010010; // 5	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b110: Y_r = 7'b0000010; // 6	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序
				//3'b111: Y_r = 7'b1111000; // 7	从右向左为abcdefg 1为不亮 0-7为数码管从右向左排序		
				default: Y_r = 7'b0000000;
		 endcase
	 endcase
	
    end    
     
endmodule

/************音频模块***************/
module	song(clk,beep); 
	input	clk;	      
	output	beep;	      
	reg beep_r=1'b0;		       
	reg[7:0] state;	     
	reg[15:0]count,count_end;
	reg[23:0]count1;
//根据频率查表计算写出音符对应的频率参数
parameter   
L_3 = 16'd75850,//低音mi
L_5 = 16'd63776,//低音so
L_6 = 16'd56818,//低音la
L_7 = 16'd50618,//低音xi
M_1 = 16'd47774,//中音do 
M_2 = 16'd42568,//中音re 
M_3 = 16'd37919,//中音mi
M_4 = 16'd35791,//中音fa
M_5 = 16'd31888,//中音so
M_6 = 16'd28409,//中音la
H_1 = 16'd23912;//高音do  
parameter	TIME = 12500000; //设置时长节拍
assign beep = beep_r;	           
always @(posedge clk )   
begin
  if(count1 < TIME)	
    count1 = count1 + 1'b1;
  else
    begin
      count1 = 24'd0;
      if(state == 8'd147)
        state <= 8'd0;
       else
         state <= state + 1'b1;    
      end
   end
always @(state)
begin
case(state)//8‘dx表示一个时间单位，count_end=x_x表示音符
  8'd0,8'd1:count_end = L_5;                      
  8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8: count_end = M_1;
  8'd9,8'd10: count_end = M_3;                                  
  8'd11,8'd12,8'd13,8'd14: count_end = M_2;	
  8'd15:count_end=M_1;
  8'd16,8'd17:count_end=M_2;
  8'd18,8'd19:count_end=M_3;
  8'd20,8'd21,8'd22,8'd23,8'd24: count_end = M_1;
  8'd25,8'd26: count_end = M_3; 
  8'd27,8'd28: count_end = M_5; 
  8'd29,8'd30,8'd31,8'd32,8'd33,8'd34,8'd35,8'd36,8'd37,8'd38: count_end = M_6;
  8'd39,8'd40,8'd41,8'd42: count_end = M_5;
  8'd43,8'd44,8'd45: count_end = M_3;
  8'd46,8'd47: count_end = M_1;
  8'd48,8'd49,8'd50,8'd51: count_end = M_2;	 
  8'd52:count_end=M_1;
  8'd53,8'd54: count_end = M_2;	
  8'd55,8'd56: count_end = M_3;	
  8'd57,8'd58,8'd59,8'd60: count_end = M_1;
  8'd61,8'd62,8'd63: count_end = L_6;
  8'd64,8'd65: count_end = L_5;
  8'd66,8'd67,8'd68,8'd69,8'd70,8'd71,8'd72,8'd73: count_end = M_1;
  8'd74,8'd75: count_end = M_6;
  8'd76,8'd77,8'd78,8'd79: count_end = M_5;
  8'd80,8'd81,8'd82: count_end = M_3;	
  8'd83,8'd84: count_end = M_1;
  8'd85,8'd86,8'd87,8'd88: count_end = M_2;	
  8'd89:count_end=M_1;
  8'd90,8'd91: count_end = M_2;	
  8'd92,8'd93: count_end = M_6;	
  8'd94,8'd95,8'd96,8'd97: count_end = M_5;
  8'd98,8'd99,8'd100: count_end = M_3;	
  8'd101,8'd102: count_end = M_5;
  8'd103,8'd104,8'd105,8'd106,8'd107,8'd108,8'd109,8'd110: count_end = M_6;
  8'd111,8'd112: count_end = H_1;
  8'd113,8'd114,8'd115,8'd116: count_end = M_5;
  8'd117,8'd118,8'd119: count_end = M_3;
  8'd120,8'd121: count_end = M_1;
  8'd122,8'd123,8'd124,8'd125: count_end = M_2;	
  8'd126:count_end=M_1;
  8'd127,8'd128: count_end = M_2;
  8'd129,8'd130: count_end = M_3;
  8'd131,8'd132,8'd133,8'd134: count_end = M_1;
  8'd135,8'd136,8'd137: count_end = L_6;
  8'd138,8'd139: count_end = L_5;
  8'd140,8'd141,8'd142,8'd143,8'd144,8'd145,8'd146,8'd147: count_end = M_1;
  default:count_end = 16'h0;//保证初始化

endcase
end
always@(posedge clk)  
begin
  count <= count + 1'b1;	
  if(count == count_end)
  begin
    count <= 16'h0;			
    beep_r <= !beep_r;				
  end
end
endmodule
/****************LCD液晶模块*****************/
module LCD1602(clk, rst, score_A, score_B, LCD_EN, RS, RW, DB);
	input clk, rst;
	input [2:0] score_A, score_B;
	output reg LCD_EN=0;	//使能引脚
	output RS, RW;	//数据命令 读写控制
	reg RS;
	output [7:0] DB;	//读写信息端
	reg [7:0] DB;
	reg [3:0] state;	//液晶模块状态机
	reg LCD_EN_sel;	//控制液晶使能端的寄存器
	reg [55:0] addr;	//显示地址
	reg [55:0] data;	//显示内容
	reg [2:0] disp_cnt;//写入计数
	reg [55:0] addr_buf;	//缓冲区
	reg [55:0] data_buf; 
	reg [7:0] score_A_data, score_B_data;
	parameter LCD_clear = 4'b0000;	//清光标并复位
	parameter set_mode = 4'b0001;	//设置功能模式
	parameter disp_on = 4'b0010;	//显示器开，光标不显示
	parameter shift_down = 4'b0011;	//文不动，光标右移
	parameter write_addr = 4'b0100;	//写入起始地址ַ
	parameter write_data = 4'b0101;	//数据


assign RW = 1'b0;
//assign LCD_EN = LCD_EN_sel ? clk : 1'b0;
always @ (LCD_EN_sel)
	begin
		 case(LCD_EN_sel)
			 1'b1: LCD_EN = clk;
			 1'b0: LCD_EN = 1'b0;
		 endcase
	end

always @(posedge clk or negedge rst)
	begin
		if(!rst) 
		begin
			LCD_EN_sel <= 1'b0;
			state <= set_mode;
			RS <= 1'b1;
			DB <= 8'h00;
			disp_cnt <= 3'b0;
		end

		else 
			begin
				case(state)
					set_mode: begin LCD_EN_sel <= 1'b1; RS <= 1'b0; DB <= 8'h38; state <= disp_on; end
					disp_on: begin DB <= 8'h0c; state <= shift_down; end
					shift_down: begin DB <= 8'h06; state <= LCD_clear; end
					LCD_clear: begin DB <= 8'h01; state <= write_addr; end
					write_addr:
						begin
							if(disp_cnt == 3'b0) 
								begin
									addr_buf <= addr;
									data_buf <= data;
									disp_cnt <= disp_cnt + 1;
								end
							else 
								begin
									RS <= 1'b0;
									DB <= addr_buf[55:48];
									addr_buf <= (addr_buf << 8);
									state <= write_data;
								end
						end
					write_data: 
					begin
						RS <= 1'b1;
						DB <= data_buf[55:48];
						data_buf <= (data_buf << 8);
						disp_cnt <= disp_cnt + 1;
						state <= write_addr;
					end
				endcase
			end
	end

always @(posedge clk)
	begin
		score_A_data <= score_A + 48;
		score_B_data <= score_B + 48;
		data <= {8'd65,8'd118,8'd115,8'd66,score_A_data,8'd58,score_B_data};
		addr <= {8'h80,8'h87,8'h88,8'h8F,8'hC0,8'hC7,8'hCF};	
	end
endmodule
