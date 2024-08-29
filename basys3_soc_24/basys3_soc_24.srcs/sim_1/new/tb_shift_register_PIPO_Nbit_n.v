`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 09:45:16
// Design Name: 
// Module Name: tb_shift_register_PIPO_Nbit_n
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


module tb_shift_register_PIPO_Nbit_n();

        parameter TEST_DATA_0 = 46;
        parameter TEST_DATA_1 = 8'b00110101;
        parameter TEST_DATA_2 = 8'hf7;
        parameter TEST_DATA_3 = 7;
        
        reg [7:0] in_data;
        reg clk, reset_p, wr_en, rd_en;
        
        wire [7:0] out_data;
                  
       shift_register_PIPO_Nbit_n #(.N(8))  DUT(
       in_data, clk, reset_p, wr_en, rd_en, out_data);
       
       initial begin
            clk = 0;
            reset_p = 1;
            in_data = 0;
            rd_en = 0;
            wr_en = 0;
       end
       
       always #5 clk = ~clk;
       
       initial begin
             #10;
             reset_p = 0;   #10;
             in_data = TEST_DATA_0; #10;
             wr_en = 1;     #10;
             wr_en = 0;  rd_en = 1; #10;
             rd_en = 0; in_data = TEST_DATA_1; #10;
             wr_en = 1;     #10;
             wr_en = 0;  rd_en = 1; #10;
             rd_en = 0; in_data = TEST_DATA_2; #10;
             wr_en = 1;     #10;
             wr_en = 0;  rd_en = 1; #10;
             rd_en = 0;  in_data = TEST_DATA_3; #10;
             wr_en = 1;     #10;
             wr_en = 0;  rd_en = 1; #10;
             $finish;
       end      
endmodule
