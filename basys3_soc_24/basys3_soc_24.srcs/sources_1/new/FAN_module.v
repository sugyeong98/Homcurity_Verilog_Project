`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/12 16:46:55
// Design Name: 
// Module Name: FAN_module
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

module fnd_cntr(
        input clk, reset_p,
        input [15:0] value,
        output  [3:0] com,
        output  [7:0] seg_7);
        
        ring_counter_fnd  rc(.clk(clk), .reset_p(reset_p), .com(com));
        
        reg [3:0] hex_value;
        always @(posedge clk)begin
                case(com)
                    4'b1110 : hex_value = value[3:0];
                    4'b1101 : hex_value = value[7:4];
                    4'b1011 : hex_value = value[11:8];
                    4'b0111 : hex_value = value[15:12];
                    default : hex_value = 4'b0000;
                endcase    
        end
        
        decoder_7seg(.hex_value(hex_value), .seg_7(seg_7));
        
endmodule

// button(채터링 문제 해결)
module button_cntr(
        input   clk, reset_p,
        input   btn,
        output  btn_pedge, btn_nedge);
        
        reg [20:0]  clk_div = 0;   
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));     // 16번 비트가 1.33ms
        
        reg debounced_btn;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)debounced_btn = 0;
                else if(clk_div_nedge)debounced_btn = btn;
        end
        
       edge_detector_p ed_btn(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge(btn_nedge), .p_edge(btn_pedge));                 
                
endmodule

////////////////////////////////////////////////////////////////
// dht module
module dht11_fan(
        input clk,
        input reset_p,
        inout dht11_data,
        output  led_G, 
        output  led_Y,
        output  led_R,
        output [15:0] value
);
        wire [7:0] humidity, temperature;  // 온습도 데이터값 출력
        dht11_cntrl dht11_inst(
            .clk(clk), 
            .reset_p(reset_p), 
            .dht11_data(dht11_data), 
            .humidity(humidity), 
            .temperature(temperature)
        );
        
        wire [15:0] humidity_bcd, temperature_bcd;  // 2진화 10진수 변환
        bin_to_dec bcd_humidity(
            .bin({4'b0, humidity}), 
            .bcd(humidity_bcd)
        );
        bin_to_dec bcd_temperature(
            .bin({4'b0, temperature}), 
            .bcd(temperature_bcd)
        );
    
        assign led_G = (temperature > 8'd24 && temperature <= 8'd27) ? 1 : 0;
        assign led_Y = (temperature > 8'd27 && temperature < 8'd30) ? 1 : 0;
        assign led_R = (temperature >= 8'd30) ? 1 : 0;
        
         assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};
    
    endmodule

///////////////////////////////////////////////
// standard white led
module fan_white_led(
        input clk, reset_p,
        input reset_w_led,
        input [3:0] btn,
        output led_r, led_g, led_b
    );
    
        reg [31:0] clk_div;
        reg [2:0] brightness;  // 밝기 단계를 위한 2비트 변수
    
        // 클럭 분주기
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
        // 버튼 눌림 감지
        wire btn_white_led;
        button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_white_led));
    
        // 밝기 단계 조절 (버튼을 누를 때마다)
        always @(posedge clk or posedge reset_p) begin
            if (reset_p || reset_w_led) brightness = 2'b00;
            else if (btn_white_led) begin
                if (brightness == 2'b11) // 최대 밝기에서 다시 처음으로
                    brightness = 2'b00; 
                else
                   brightness = brightness + 1;
            end
        end
    
        wire [31:0] duty_r, duty_g, duty_b;
    
        // 각 색상별로 밝기 단계에 따른 듀티 싸이클 설정
        assign duty_r = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd20 :
                        (brightness == 2'b10) ? 32'd50 : 
                                                 32'd100; //0%,20%,50%,100%
    
        assign duty_g = duty_r;  // 동일한 듀티 싸이클 사용 (필요시 각 색상별로 다르게 설정 가능)
        assign duty_b = duty_r;  // 동일한 듀티 싸이클 사용
    
        
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_r( .clk(clk), .reset_p(reset_p), .duty(duty_r), .pwm(led_r));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_g( .clk(clk), .reset_p(reset_p), .duty(duty_g), .pwm(led_g));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_b( .clk(clk), .reset_p(reset_p), .duty(duty_b), .pwm(led_b));
    
endmodule

// 캠핑모드 주황색 LED 밝기 조절 코드
////////////////////////////////////////////////////////////////////////
module camp_yellow_led(
        input clk, reset_p,
        input reset_y_led,
        input [3:0] btn,
        output y_led_r, y_led_g, y_led_b
    );
    
        reg [31:0] clk_div;
        reg [2:0] brightness;  // 밝기 단계를 위한 2비트 변수
        
        // 클럭 분주기
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
        // 버튼 눌림 감지
        wire btn_yellow_led;
        button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_yellow_led));
    
        // 밝기 단계 조절 (버튼을 누를 때마다)
        always @(posedge clk or posedge reset_p) begin
            if (reset_p || reset_y_led) brightness = 2'b00;
            else if (btn_yellow_led) begin
                if (brightness == 2'b11) // 최대 밝기에서 다시 처음으로
                    brightness = 2'b00; 
                else
                    brightness = brightness + 1;
            end
        end
    
        wire [31:0] duty_g, duty_r;
    
        // 초록색 LED에만 밝기 단계에 따른 듀티 싸이클 설정
        assign duty_g = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd10 :
                        (brightness == 2'b10) ? 32'd20 :
                                                 32'd30; //0%,10%,20%,30%
        
         assign duty_r = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd40 :
                        (brightness == 2'b10) ? 32'd70 : 
                                                 32'd100; //0%,40%,70%,100%
        
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_g( .clk(clk), .reset_p(reset_p), .duty(duty_g), .pwm(y_led_g));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_r( .clk(clk), .reset_p(reset_p), .duty(duty_r), .pwm(y_led_r));
    
endmodule

module T_flip_flop_p_reset(
        input clk, reset_p,
        input t,
        input timer_reset,
        output reg q);
    
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)q = 0;
            else begin
                if(t) q = ~q;
                else if(timer_reset) q = 0;
                else q = q;
            end
        end
endmodule

module dc_motor_pwm_mode(
        input clk, reset_p,
        input timer_reset,
        input [3:0] btn,
        output [15:0] led,
        output motor_pwm,
        output survo_pwm);
          
        button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_fan_step));
        button_cntr btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_fan_rotation));
       
        reg [2:0] led_count;
        reg [5:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p || timer_reset)begin
                        duty = 0;
                end
                else if(btn_fan_step) begin
                        duty = duty + 1;
                        if(duty >= 4) duty = 0;
                end
        end
       
        always @(posedge clk or posedge reset_p)begin
                    if(reset_p || timer_reset) led_count = 3'b000;
                    else if(btn_fan_step)begin
                        if(led_count == 3'b111) led_count = 3'b000;
                        else led_count = {led_count[1:0], 1'b1};
                    end
            end
           
         assign led = led_count;
       
         pwm_Nstep_freq #(
            .duty_step(4),
            .pwm_freq(100))
         pwm_motor(
            .clk(clk),        
            .reset_p(reset_p), 
            .duty(duty),      
            .pwm(motor_pwm)     
        );
       
         reg [31:0] clk_div;
    
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
    
        wire clk_div_22_pedge;
    
    
        edge_detector_p ed(
            .clk(clk),
            .reset_p(reset_p),
            .cp(clk_div[22]),
            .p_edge(clk_div_22_pedge)
        );
       
        T_flip_flop_p_reset en(.clk(clk), .reset_p(reset_p),.t(btn_fan_rotation), .timer_reset(timer_reset), .q(on_off));
       
        reg [7:0] sv_duty;     
        reg down_up;    
        reg [7:0] duty_min, duty_max;
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                sv_duty = 16;    
                down_up = 0;
                duty_min = 16;
                duty_max = 96;
            end
            else if (clk_div_22_pedge && on_off) begin
                if (timer_reset) begin
                    sv_duty = sv_duty;              
                end
                else if (!down_up) begin
                    if (sv_duty < duty_max) 
                        sv_duty = sv_duty + 1;
                    else
                        down_up = 1; 
                end
                else begin
                    if (sv_duty > duty_min)  
                        sv_duty = sv_duty - 1;
                    else
                        down_up = 0; 
                end
            end
        end
    
    
         pwm_Nstep_freq #(
            .duty_step(800),  
            .pwm_freq(50)  
               ) sv_motor(
            .clk(clk),
            .reset_p(reset_p),
            .duty(sv_duty),
            .pwm(survo_pwm)
        );
    

endmodule
/////////////////////////////////////////////////
// Timer Counter
module loadable_down_counter_state(
        input clk,
        input reset_p,
        input [3:0] btn,
        output reg [3:0] bcd1_out,
        output reg [3:0] bcd10_out,
        output reg timer_done);

        wire clk_usec, clk_msec, clk_sec;
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));  
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));    
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));
       
        button_cntr btn_timer_start(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(next_timer));
             
        parameter S_0s  = 4'b0001;
        parameter S_3s  = 4'b0010;
        parameter S_5s  = 4'b0100;
        parameter S_10s = 4'b1000;
        reg [3:0] state, next_state;
       
            reg [3:0] bcd1, bcd10;
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) state = S_0s;
            else state = next_state;
        end
       
            always @(negedge clk or posedge reset_p) begin
            if (reset_p) begin
                next_state = S_0s;
                bcd1 = 0;
                bcd10 = 0;
                timer_done = 0;
            end
            else begin
                case (state)
                    S_0s: begin
                        bcd1  = 3;
                        bcd10 = 0;
                        timer_done = 0;
                        if (next_timer) begin
                            timer_done = 0;
                            next_state = S_3s;
                        end
                    end
                    S_3s : begin
                        bcd1  = 5;
                        bcd10 = 0;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                            next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_5s;
                        end
                    end
                    S_5s: begin
                        bcd1  = 0;
                        bcd10 = 1;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                            next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_10s;
                        end
                    end
                    S_10s: begin
                        bcd1  = 0;
                        bcd10 = 0;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                             next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_0s;
                        end
                    end
                    default: next_state = S_0s;
                endcase
            end
        end
       
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                bcd1_out  = 0;
                bcd10_out = 0;
            end
            else if (next_timer) begin
                    bcd1_out  = bcd1;
                    bcd10_out = bcd10;
            end        
            else if (clk_sec) begin
                    if(bcd1_out == 0)begin
                        if(bcd10_out > 0)begin
                            bcd10_out = bcd10_out - 1;
                            bcd1_out  = 9;
                        end
                    end    
                    else begin
                            bcd1_out = bcd1_out - 1;
                    end    
            end
        end
endmodule
    
