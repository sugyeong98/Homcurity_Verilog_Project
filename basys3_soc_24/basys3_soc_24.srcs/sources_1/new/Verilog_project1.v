`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/25 16:56:02
// Design Name: 
// Module Name: Verilog_project1
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

module MP_watch(
    input clk, reset_p,   
    input [4:0] btn,   
    output [3:0] com,    
    output [7:0] seg_7,
    output [2:0] led_mode,
    output reg led_start, led_lap, led_alarm, led_start_timer, 
    output buzz);
   
    wire [2:0] btn_mode_ring;
    wire [4:0] watch_btn, stopwatch_btn, cooktimer_btn;
    wire [15:0] watch_value, stopwatch_value, cooktimer_value;
    reg [15:0] fnd_value;
    
    parameter watch_mode = 3'b001;
    parameter stopwatch_mode = 3'b010;
    parameter cooktimer_mode = 3'b100;
     
    // 모드 변경을 위한 ring counter
    ring_counter_mode mode_ring( .clk(clk), .reset_p(reset_p), .btn(btn), .btn_mode_ring(btn_mode_ring), .led_mode(led_mode));
    
    // Watch 모듈 인스턴스
    loadable_watch_project watch( .clk(clk), .reset_p(reset_p), .btn(watch_btn), .value(watch_value));
    
    // Stopwatch 모듈 인스턴스
    stop_watch_project stopwatch( .clk(clk), .reset_p(reset_p), .btn(stopwatch_btn), .value(stopwatch_value)
            , .led_start(stopwatch_led_start), .led_lap(stopwatch_led_lap));
    
    // Cook timer 모듈 인스턴스
    cook_timer_project cooktimer( .clk(clk), .reset_p(reset_p), .btn(cooktimer_btn), .value(cooktimer_value)
            , .led_alarm(cooktimer_led_alarm), .led_start_timer(cooktimer_led_start), .buzz(buzz));
    
    // mux로 각 모드마다 다른 버튼이 입력되지 않게 막음
    assign watch_btn = (btn_mode_ring == watch_mode) ? btn : 5'b00000;
    assign stopwatch_btn = (btn_mode_ring == stopwatch_mode) ? btn : 5'b00000;
    assign cooktimer_btn = (btn_mode_ring == cooktimer_mode) ? btn : {btn[4], 4'b0000};
     
    // 모드에 따른 기능 부여
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)begin
             fnd_value <= watch_value;
             led_start  <= 0;
             led_lap  <= 0;    
             led_alarm <= 0;  
             led_start_timer <= 0;
        end     
        else begin
            case (btn_mode_ring)
                watch_mode: begin
                    fnd_value <= watch_value;
                    led_start <= 0;
                    led_lap <= 0;
                    led_alarm <= cooktimer_led_alarm;
                    led_start_timer <= 0;
                end    
                stopwatch_mode: begin
                    fnd_value <= stopwatch_value;
                    led_start <= stopwatch_led_start;
                    led_lap <= stopwatch_led_lap;
                    led_alarm <= cooktimer_led_alarm;
                    led_start_timer <= 0;
                end
                cooktimer_mode: begin
                    fnd_value <= cooktimer_value;
                    led_start <= 0;
                    led_lap <= 0;
                    led_alarm <= cooktimer_led_alarm;
                    led_start_timer <= cooktimer_led_start;
                end    
            endcase
        end
    end   
     // FND 제어 모듈
    fnd_cntrl fnd( .clk(clk), .reset_p(reset_p), .value(fnd_value), .com(com), .seg_7(seg_7));

endmodule