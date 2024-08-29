`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 15:26:39
// Design Name: 
// Module Name: tb_shift_register_SIPO_Nbit_n
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_shift_register_SIPO_Nbit_n();
        reg d;
        reg clk, reset_p;
        reg rd_en;
        wire [7:0] q;

        parameter data = 8'b10100011;
        
        shift_register_SIPO_Nbit_n #(.N(8)) DUT(d, clk, reset_p, rd_en, q);
        // 입력선 연결할때 변수 선언 순서대로 해도 된다        
        
        initial begin
            clk = 0;
            reset_p = 1;
            d = data[0];        // 어떤 값을 넣어도 상관은 없음, 어차피 리셋 
            rd_en = 1;          //enable 활성화 
       end
       
       always #5 clk = ~clk;
       
       integer i;
       initial begin
            #10;
            reset_p = 0; #10;        // 리셋을 다시 풀고, 10ns clk 
            for(i=0;i<8;i=i+1)begin
                #10; d = data[i];
            end
            rd_en = 0;  #1;
            $finish;    
       end     
      
endmodule
