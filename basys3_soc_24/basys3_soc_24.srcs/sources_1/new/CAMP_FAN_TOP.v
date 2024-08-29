`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/12 18:49:49
// Design Name: 
// Module Name: CAMP_FAN_TOP
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

module CAMP_FAN_TOP(
        input clk, reset_p,
        input switch_mode,
        inout dht11_data,
        input [3:0] btn,
        output led_mode,
        output [14:0] led,
        output  led_r, led_g, led_b, 
        output  y_led_r, y_led_g, y_led_b,     // 외부 3색 led
        output  led_G, led_Y, led_R,              // 외부 단색 led 3개         
        output motor_pwm, survo_pwm,
        output [3:0] com,
        output [7:0] seg_7);
        
        reg reset_y_led, reset_w_led;
        reg [15:0] fnd_value;
        reg [3:0] camp_btn, std_btn;
        wire timer_done;
        
        fan_white_led( .clk(clk), .reset_w_led(reset_w_led), .reset_p(reset_p), .btn(std_btn), .led_r(led_r), .led_g(led_g), .led_b(led_b));           // 백색광 
        camp_yellow_led( .clk(clk), .reset_y_led(reset_y_led), .reset_p(reset_p), .btn(camp_btn), .y_led_r(y_led_r), .y_led_g(y_led_g), .y_led_b(y_led_b));     // 주광색 
        
        dc_motor_pwm_mode( .clk(clk), .reset_p(reset_p), .timer_reset(timer_done), .btn(btn), .led(led), .motor_pwm(motor_pwm), .survo_pwm(survo_pwm));
        
        // RGB led reset button control 
        button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(w_led));
        button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(y_led));
        
        // Timer control 
        wire [3:0] cur_sec10, cur_sec1;
        wire dec_clk;
        loadable_down_counter_state( .clk(clk), .reset_p(reset_p), .btn(std_btn), .bcd1_out(cur_sec1), .bcd10_out(cur_sec10), .timer_done(timer_done));
        
        wire [7:0] cur_time;
        wire [15:0] timer_value;
        assign cur_time = {cur_sec10, cur_sec1};
        assign timer_value = {8'b0, cur_time};
        
        // dht sensor + led 3
        wire [15:0] dht_value;
        dht11_fan( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .led_G(led_G), .led_Y(led_Y), .led_R(led_R), .value(dht_value));
        
        // mode change
        assign camp_std = switch_mode;
        assign led_mode = camp_std;       // mode check led
                
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        fnd_value = 0;
                end
                else if(camp_std)begin          // camping mode
                        fnd_value = dht_value;
                        camp_btn = btn;
                        std_btn = {3'b000, btn[0]};
                        if(y_led)begin
                            reset_y_led = 0;
                            reset_w_led = 1;
                        end
                        else if(w_led)begin
                            reset_y_led = 1;
                            reset_w_led = 0;
                        end
                end
                else if(!camp_std)begin     // standard mode
                        fnd_value = timer_value;
                        camp_btn = 4'b0000;
                        std_btn = btn;
                        reset_y_led = 1;
                        reset_w_led = 0;
                end
        end
        
        fnd_cntr fnd( .clk(clk), .reset_p(reset_p), .value(fnd_value), .com(com), .seg_7(seg_7));

endmodule
