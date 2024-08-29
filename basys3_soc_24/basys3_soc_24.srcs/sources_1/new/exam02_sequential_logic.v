`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/24 16:34:25
// Design Name: 
// Module Name: exam02_sequential_logic
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

// D - flipflop 하강엣지 동작
module D_flip_flop_n(
        input d,
        input clk, reset_p, enable,
        output reg q);
                                                                                              // 하강엣지 동작 + 리셋기능
        always @(negedge clk or posedge reset_p)begin              // 하강엣지(negative edge) , 상승엣지(positive edge)
                if(reset_p) q = 0;
                else if(enable) q = d;
        end
        
endmodule

// D - flipflop 상승엣지 동작
module D_flip_flop_p(
        input d,
        input clk, reset_p, enable,
        output reg q);
                                                                                               // 상승엣지 동작 + 리셋기능
        always @(posedge clk or posedge reset_p)begin              // 하강엣지(negative edge) , 상승엣지(positive edge)
                if(reset_p) q = 0;                                                      // reset = 1 , 무조건 0 출력
                else if(enable) q = d;                                                // enable = 1, flipflop 동작 / = 0, 불변   
        end
endmodule

// T - flipflop 하강엣지
module T_flip_flop_n(
        input clk, reset_p,
        input t,
        output reg q);
        
        always  @(negedge clk or posedge reset_p)begin
                if(reset_p) q = 0;
                else begin
                        if(t) q = ~q;                   // toggle 
                        else q = q;                    // latch             
               end
       end   

endmodule

// T-flipflop 상승엣지
module T_flip_flop_p(
        input clk, reset_p,
        input t,
        output reg q);
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) q = 0;
                else begin
                        if(t) q = ~q;                   // toggle 
                        else q = q;                    // latch             
               end
       end   

endmodule

// 비동기식 up 카운터
module up_counter_asyc(
        input clk, reset_p,
        output [3:0] count);            // reg가 아닌 wire이므로 0으로 초기화하면 안됨
        // 초기화하는 이유는 이전값을 유지하여 출력하는 경우 모르는 값이 출력되기 때문        
        // reset 기능이 있는 이유! 이전값을 초기화시키기 위해서!
        T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
        T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
        T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
        T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
        
endmodule

//비동기식 down 카운터
module down_counter_asyc(
        input clk, reset_p,
        output [3:0] count);
        
        T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
        T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
        T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
        T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
        
endmodule
// 비동기식의 문제점 : PDT 때문에 중간중간 불필요한 값이 출력

//동기식 up카운터
// T - flip flop 을 사용하면 비효율적으로 나와서 D 사용 
//상승엣지
module upcounter_p(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop의 출력  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count +1;
        end        
endmodule
//하강엣지
module upcounter_n(
        input clk, reset_p, enable,
        output reg [3:0] count);
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count +1;
        end        
endmodule

//동기식 down 카운터
//상승엣지
module downcounter_p(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop의 출력  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count - 1;
        end        
endmodule

//하강엣지
module downcounter_n(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop의 출력  
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count - 1;
        end        
endmodule

//동기식 BCD 카운터 
//up-counter
module bcd_upcounter_p(
        input clk,reset_p,
        output reg [3:0] count);

        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;                      // 초기값 설정 
                else begin
                        if(count >= 9) count = 0;        // 혹시라도 10이 되는 순간을 막을 수 있음
                        else count = count + 1;         
                end
        end
endmodule        

//down-counter
module bcd_downcounter_p(
        input clk, reset_p,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 9;
                else begin
                        if(count >= 10 | count == 0) count = 9; // count >= 10 : 만에 하나 10보다 큰 수가 나올경우 대비 
                        else count = count -1;
                end
        end
endmodule

//4비트 up/down counter
module updowncounter_p(
        input clk, reset_p,
        input up_down,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else begin
                        if(up_down) begin                           // up_down = 1 이면 증가
                            count = count + 1;                      
                        end
                        else begin                                      //  up_down = 0 이면 감소
                            count = count - 1;                  
                        end
                end
        end
endmodule

// BCD up/down counter
module bcd_updowncounter_p(
        input clk, reset_p,
        input up_down,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    if(reset_p) count = 0;                                          // up_down = 1 이면 0으로 초기화
                    else count = 9;                                                   // up_down = 0 이면 9로 초기화   
                end
                   
                else begin
                        if(up_down) begin                                            // up_down = 1 이면 증가
                            if(count >= 9) count = 0;
                            else count = count + 1;                      
                        end
                        else begin
                            if(count == 0 | count >= 10) count = 9;           //  up_down = 0 이면 감소
                            else count = count - 1;                  
                        end
                end
        end
endmodule

//Ring counter
module ring_counter(
        input clk, reset_p,
        output  reg [3:0]   q);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) q = 4'b0001;
                else begin
                        if(q == 4'b1000) q = 4'b0001;
                        else q[3:0] = {q[2:0], 1'b0};
                end
       end
       // 기본 틀                    
//        always @(posedge clk or posedge reset_p)begin
//                if(reset_p)q =4'b0001;
//                else begin
//                    case(q)
//                        4'b0001: q = 4'b0010;
//                        4'b0010: q = 4'b0100;
//                        4'b0100: q = 4'b1000;
//                        4'b1000: q = 4'b0001;
//                        default: q = 4'b0001; 
//                    endcase
//                end
//        end
endmodule                

// Ring counter led
module ring_counter_led(
        input clk, reset_p,
        output reg [15:0] led);
        
        reg [24:0]  clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[24]), .n_edge(clk_div_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) led = 16'b0000_0000_0000_0001;
                else if(clk_div_nedge)begin
                    if(led == 16'b1000_0000_0000_0000) led = 16'b0000_0000_0000_0001; 
                    else led = {led[14:0], 1'b0};
                    //else led[15:0] = {led[14:0], 1b'0}; 결합연산자 사용해서 shift 연산자 대신 사용 가능
                end
        end
endmodule



// T-flipflop Edge Detector (positive)
module edge_detector_p(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
                // ff_cur <= 0;
                // ff_old <= 0;
            end
            else begin      // else 문 안에서는 병렬식 진행이 아닌 순서진행 
                ff_old = ff_cur;
                ff_cur = cp;            // blocking 
                // ff_cur <= cp;
                // ff_old <= ff_cur;    /non-blocking 
                // 대입연산자기준 오른쪽 값을 먼저 정한 후 왼쪽에 대입한다. cp와 ff_cur 값을 정하고 그 다음 왼쪽에 대입
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule


// T-flipflop Edge Detector (negative)
module edge_detector_n(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(negedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
                // ff_cur <= 0;
                // ff_old <= 0;
            end
            else begin      // else 문 안에서는 병렬식 진행이 아닌 순서진행 
                ff_old = ff_cur;
                ff_cur = cp;            // blocking 
                // ff_cur <= cp;
                // ff_old <= ff_cur;    /non-blocking 
                // 대입연산자기준 오른쪽 값을 먼저 정한 후 왼쪽에 대입한다. cp와 ff_cur 값을 정하고 그 다음 왼쪽에 대입
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule

// memory
// 4bit register(직렬입력 - 직렬출력) (Serial In - Serial Out)
module shift_register_SISO_n(
        input d,
        input clk, reset_p,
        output q);
        
        reg [3:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {d, siso_reg[3:1]};     // 결합연산자를 사용한 shift
//                        siso_reg[3] <= d;
//                        siso_reg[2] <= siso_reg[3];
//                        siso_reg[1] <= siso_reg[2];
//                        siso_reg[0] <= siso_reg[1];         // non-blocking(왼쪽값 한번에 결정하고 오른쪽값에 대입/병렬식)
                end                     
        end
        assign q = siso_reg[0];
                        
endmodule

// nbit register(직렬입력 - 직렬출력)
// 0번비트 먼저 입력 , 0번비트 먼저 출력 
//  data값을 최하위비트(LSB)부터 받을때
module shift_register_SISO_Nbit_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        output q);
        
        reg [N-1:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {d, siso_reg[N-1:1]};     // 결합연산자를 사용한 shift
                end                     
        end
        assign q = siso_reg[0];       
endmodule

// data값을 최상위비트(MSB)부터 받을때
// 최상위 비트 먼저 입력, 먼저 출력 
module shift_register_SISO_Nbit_msb_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        output q);
        
        reg [N-1:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {siso_reg[N-2:0], d};     // 결합연산자를 사용한 shift
                end                     
        end
        assign q = siso_reg[N-1];       
endmodule


// 4bits register 직입병출(Serial In - Parallel Out) 
module shift_register_SIPO_n( 
        input d,
        input clk, reset_p,
        input rd_en,
        output [3:0] q);
        
        reg [3:0] sipo_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) sipo_reg <= 0;
                else begin
                        sipo_reg <= {d, sipo_reg[3:1]};  
                end                     
        end
        
        assign q = rd_en ? 4'bz : sipo_reg;     // 게이트 프리미티브 사용 안하고 mux를 이용하여 설계
                                                                // 삼상버퍼 Active Low
//        bufif0 (q[0]], sipo_reg[0], rd_en);     // 삼상버퍼의 게이트 프리미티브(입력, 출력, 출력)
endmodule

// Nbits register 직입병출(Serial In - Parallel Out) 
module shift_register_SIPO_Nbit_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        input rd_en,
        output [N-1:0] q);
        
        reg [N-1:0] sipo_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) sipo_reg <= 0;
                else begin
                        sipo_reg <= {d, sipo_reg[N-1:1]};  
                end                     
        end
        
        assign q = rd_en ? 'bz : sipo_reg;      // z = 임피던스(앞에 비워두면 비트수에 상관없이 전부 z로 채움)
endmodule


// 4bits register 병입직출(Parallel In - Serial Out)
module shift_register_PISO_n( 
        input [3:0] d,
        input clk, reset_p,
        input shift_load,               // shift = 1 , load = 0
        output q);
        
        reg [3:0] piso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) piso_reg <= 0;
                else begin
                       if(shift_load)begin
                            piso_reg <= {1'b0, piso_reg[3:1]};
                       end
                       else begin
                            piso_reg = d;
                       end  
                end                     
        end
        assign q = piso_reg[0];
endmodule

// Nbits register 병입직출(Parallel In - Serial Out)
module shift_register_PISO_Nbit_n #(parameter N = 8)( 
        input [N-1:0] d,
        input clk, reset_p,
        input shift_load,               // shift = 1 , load = 0
        output q);
        
        reg [N-1:0] piso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) piso_reg <= 0;
                else begin
                       if(shift_load)begin
                            piso_reg <= {1'b0, piso_reg[N-1:1]};
                       end
                       else begin
                            piso_reg = d;
                       end  
                end                     
        end
        assign q = piso_reg[0];
endmodule

// 4bit register 병입병출(Parallel In - Parallel OUT)
module shift_register_PIPO_n(
         input [3:0] in_data,
        input clk, reset_p, wr_en, rd_en,
        output [3:0] out_data);
                     
        reg [3:0] register;                                                                                     
        always @(negedge clk or posedge reset_p)begin              
               if(reset_p) register = 0;
               else if(wr_en) register = in_data;      // wr_en 1일때 register에 입력데이터 저장 
        end   
        
         assign out_data = rd_en ? register : 'bz;     
endmodule

// Nbit register 병입병출(Parallel In - Parallel OUT)
module shift_register_PIPO_Nbit_n #(parameter N = 8)(
        input [N-1:0] in_data,
        input clk, reset_p, wr_en, rd_en,
        output [N-1:0] out_data);
        
        reg [N-1:0] register;                                                                                     
        always @(negedge clk or posedge reset_p)begin              
                if(reset_p) register = 0;
                else if(wr_en) register = in_data;      // wr_en 1일때 register에 입력데이터 저장 
        end
        
        assign out_data = rd_en ? register : 'bz;      // 임피던스 : 현상 유지         
endmodule

// 1024개의 8비트 sram
module sram_8bit_1024(
        input clk,
        input wr_en, rd_en,
        input [9:0] address,  // 1024개의 주소를 만들기 위해 10개의 비트를 가져야함
        inout [7:0] data);      // input, output 둘다 사용가능(각각의 기능을 사용할때는 다른 하나의 기능을 막아야함) 
        
        reg [7:0] memory [0:1023];  // memory 배열 선언
        
        always @(posedge clk)begin
                if(wr_en) memory[address] = data;       // memory의 address 번째 주소에 data 값 저장 
        end
        
        assign data = rd_en ? memory[address] : 'bz;
        
endmodule