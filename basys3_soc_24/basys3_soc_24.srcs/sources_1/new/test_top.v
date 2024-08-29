`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 14:15:33
// Design Name: 
// Module Name: test_top
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

module board_led_switch_test_top(
        input [15:0] switch,
        output [15:0] led);
        
        assign led = switch;
        
endmodule

module led_top_test(
        output led_y, led_g
);
        assign led_y = 1;
        assign led_g = 1;
endmodule

module fnd_test_top(
        input clk, reset_p,             // xdc
        input [15:0] switch,            // xdc     
        output  [3:0] com,               // xdc
        output  [7:0] seg_7);            // xdc
        
        fnd_cntrl  fnd( .clk(clk), .reset_p(reset_p), .value(switch), .com(com), .seg_7(seg_7));
        
endmodule

//FND Ring counter(com)
module ring_counter_fnd(
        input clk, reset_p,
        output  reg [3:0] com);
        
        reg [20:0]  clk_div = 0;        // '= 0'은 시뮬레이션 편의상 0으로 초기화 / 보드에서는 영향없음 
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) com = 4'b1110;
                else if(clk_div_nedge) begin
                        if(com == 4'b0111) com = 4'b1110;
                        else com[3:0] = {com[2:0], 1'b1};
                end
       end
endmodule                

//FND WATCH 출력
module watch_top(
        input clk, reset_p,     // xdc
        input [2:0] btn,         // xdc
        output  [3:0] com,    // xdc
        output  [7:0] seg_7);   // xdc
        
        wire btn_mode;
        wire btn_sec;
        wire btn_min;
        wire set_watch;     // 1이면(누르면) set , 0이면 watch
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min, clk_hour;
        wire [3:0] sec_1,sec_10, min_1, min_10;
        wire [15:0] value;
        // 종류별 버튼 기능 부여
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));                           // 채터링 문제 해결 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
        
//        edge_detector_n    ed_btn_mode(.clk(clk), .reset_p(reset_p), .cp(btn[0]), .p_edge(btn_mode));       // 채터링 문제발생 유발 
//        edge_detector_n    ed_btn_sec(.clk(clk), .reset_p(reset_p), .cp(btn[1]), .p_edge(btn_sec));
//        edge_detector_n    ed_btn_min(.clk(clk), .reset_p(reset_p), .cp(btn[2]), .p_edge(btn_min));
        
        // 입력값에 따른 모드 설정 
        T_flip_flop_p   t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode), .q(set_watch));
        
        // 모드 설정에 따른 입력값 다르게 
        assign  inc_sec =  set_watch ? btn_sec : clk_sec;        // set 모드에서는 초 증가, watch모드에서는 시계모드
        assign  inc_min = set_watch ? btn_min : clk_min;        // set 모드에서는 분 증가, watch모드에서는 시계모드
        
        // 주기 생성 
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));         // 1s   
        clock_div_60    min_clk( .clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));        // 1min 
       
        // 60진 카운터 
        counter_bcd_60 counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(inc_sec), .bcd1(sec_1), .bcd10(sec_10));     
        counter_bcd_60 counter_min(.clk(clk), .reset_p(reset_p), .clk_time(inc_min), .bcd1(min_1), .bcd10(min_10));  
        
        // FND 출력
        assign value = {min_10, min_1, sec_10, sec_1};
        fnd_cntrl  fnd( .clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
        
endmodule

// loadable Watch(Upgrade Version)
// 모드가 변경되어도 동기화되어서 시간이 맞춰서 흐른다
module loadable_watch_top(
        input clk, reset_p,        // xdc
        input [2:0] btn,             // xdc
        output  [3:0] com,        // xdc
        output  [7:0] seg_7);    // xdc
        
        wire btn_mode;
        wire btn_sec;
        wire btn_min;
        wire set_watch;          // 1이면(누르면) set , 0이면 watch
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min, clk_hour;
        wire watch_load_en, set_load_en;
        
        // 버튼 종류별기능 부여 (채터링 문제 해결)
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));                  
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
                
        // 모드 변경 버튼 토글 설정 
        T_flip_flop_p   t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode), .q(set_watch));
        
        // 시간 동기화(load)
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(set_watch), .n_edge(watch_load_en), .p_edge(set_load_en));
        
        // 모드에 따른 대입 값 변경 선언 
        assign  inc_sec =  set_watch ? btn_sec : clk_sec;        // set 모드에서는 초 증가, watch모드에서는 시계모드
        assign  inc_min = set_watch ? btn_min : clk_min;        // set 모드에서는 분 증가, watch모드에서는 시계모드
        
        // 주기 생성
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));         // 1s   
        clock_div_60    min_clk( .clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));        // 1min 
       
        // loadable 60진 카운터 
        loadable_counter_bcd_60 sec_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(watch_load_en),
            .load_bcd1(set_sec_1), .load_bcd10(set_sec_10),
            .bcd1(watch_sec_1), .bcd10(watch_sec_10));    
        loadable_counter_bcd_60 min_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(watch_load_en),
            .load_bcd1(set_min_1), .load_bcd10(set_min_10),
            .bcd1(watch_min_1), .bcd10(watch_min_10));
        loadable_counter_bcd_60 sec_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_sec), .load_enable(set_load_en),
            .load_bcd1(watch_sec_1), .load_bcd10(watch_sec_10),
            .bcd1(set_sec_1), .bcd10(set_sec_10));    
        loadable_counter_bcd_60 min_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_min), .load_enable(set_load_en),
            .load_bcd1(watch_min_1), .load_bcd10(watch_min_10),
            .bcd1(set_min_1), .bcd10(set_min_10));     
            
         // FND 출력
        wire [3:0] watch_sec_1,watch_sec_10, watch_min_1, watch_min_10;
        wire [3:0] set_sec_1,set_sec_10, set_min_1, set_min_10;
        wire [15:0] value, watch_value, set_value;  
          
        assign watch_value = {watch_min_10, watch_min_1, watch_sec_10, watch_sec_1};
        assign set_value = {set_min_10, set_min_1, set_sec_10, set_sec_1};
        assign value = set_watch ? set_value : watch_value;
        fnd_cntrl  fnd( .clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
        
endmodule

// STOP watch (start, stop, lap, clear)
module  stop_watch_top(
        input   clk, reset_p,
        input   [2:0] btn,
        output  [3:0] com,
        output  [7:0] seg_7,
        output  led_start, led_lap);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire btn_start, btn_lap, btn_clear;
        wire [3:0] sec_1, sec_10, min_1, min_10;
        wire clk_start;
        wire start_stop; 
        reg lap;
        wire [15:0] value;
        wire reset_start;
        
        // 시스템 리셋 버튼 / 클리어 버튼 분류
        assign reset_start = reset_p | btn_clear;
        // start / stop 버튼 대입 값 선언 
        assign clk_start = start_stop ? clk : 0;
        
        // 주기 생성 
        clock_div_100   usec_clk( .clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        clock_div_60      min_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   // 1min 
        
        // 종류별 버튼 기능 부여(채터링 문제 해결) 
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));   
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));
        
        // start, stop 모드 토글 설정 + led on/off 
        T_flip_flop_p  t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
        assign  led_start = start_stop;
         
        // lap 모드 변경(lap 리셋 / 클리어 버튼 따로 생성) 
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) lap = 0;
                else begin
                        if(btn_lap) lap = ~lap;     // lap 토글 
                        else if(btn_clear) lap = 0;
               end
        end   
        // lap 모드 변경
//      T_flip_flop_p  t_lap(.clk(clk), .reset_p(reset_start), .t(btn_lap), .q(lap));
        assign  led_lap = lap;
        
        // clear기능이 있는 60진 카운터
        counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec_1), .bcd10(sec_10));     
        counter_bcd_60_clear counter_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .clear(btn_clear), .bcd1(min_1), .bcd10(min_10));
        
        reg [15:0] lap_time;
        wire [15:0] cur_time;
        assign  cur_time = {min_10, min_1, sec_10, sec_1};      // 현재 시간 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) lap_time = 0;
                else if(btn_lap) lap_time = cur_time;                    // lap 버튼이 눌리면 현재 시간 저장
                else if(btn_clear) lap_time = 0; 
        end  

        // FND 출력 
        assign value = lap ? lap_time : cur_time;
        fnd_cntrl  fnd( .clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule

// cmsecond STOP watch
// lap, clear 추가
module  detail_stop_watch_top(
        input   clk, reset_p,
        input   [2:0] btn,
        output  [3:0] com,
        output  [7:0] seg_7,
        output  led_start, led_lap);
        
        wire clk_usec, clk_msec, clk_csec, clk_sec;
        wire btn_start, btn_lap, btn_clear;
        wire [3:0] sec_1, sec_10, cms_1, cms_10;
        wire clk_start;
        wire start_stop; 
        reg lap;
        wire [15:0] value;
        wire reset_start;
        
        assign reset_start = reset_p | btn_clear;
        assign clk_start = start_stop ? clk : 0;
        
        // 주기 생성 
        clock_div_100   usec_clk( .clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms
        clock_div_10  csec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_10(clk_csec));     // 10ms  = 1 cms
        clock_div_1000  sec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));       // 1 sec   
        
        // 종류별 버튼 기능 부여
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));                           // 채터링 문제 해결 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));
        
        // start, stop 모드 변경 
        T_flip_flop_p  t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
        assign  led_start = start_stop;
         
        // lap 모드 변경(lap 리셋 / 클리어 버튼 따로 생성) 
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) lap = 0;
                else begin
                        if(btn_lap) lap = ~lap;     // lap 토글 
                        else if(btn_clear) lap = 0;
               end
        end   
        // lap 모드 변경
//      T_flip_flop_p  t_lap(.clk(clk), .reset_p(reset_start), .t(btn_lap), .q(lap));
        assign  led_lap = lap;
        
        // clear기능이 있는 60진 카운터
        counter_bcd_100_clear counter_csec(.clk(clk), .reset_p(reset_p), .clk_time(clk_csec), .clear(btn_clear), .bcd1(cms_1), .bcd10(cms_10));
        counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec_1), .bcd10(sec_10));
         
        reg [15:0] lap_time;
        wire [15:0] cur_time;
        assign  cur_time = {sec_10, sec_1, cms_10, cms_1};      // 현재 시간 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) lap_time = 0;
                else if(btn_lap) lap_time = cur_time;                    // lap 버튼이 눌리면 현재 시간 저장
                else if(btn_clear) lap_time = 0; 
        end  

        // FND 출력 
        assign value = lap ? lap_time : cur_time;
        fnd_cntrl  fnd( .clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule

// 주방  타이머 
module cook_timer_top(
        input clk, reset_p,
        input [3:0] btn,
        output [3:0] com,
        output [7:0] seg_7,
        output led_alarm, led_start, buzz);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire btn_start, btn_sec, btn_min, btn_alarm_off;
        wire [3:0] set_sec_1, set_sec_10, set_min_1, set_min_10;
        wire [3:0] cur_sec_1, cur_sec_10, cur_min_1, cur_min_10;
        wire dec_clk;
        reg start_set, alarm;
        wire [15:0] value, set_time, cur_time;
        
        // 주기 설정 
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        
        // 버튼 기능 부여
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start)); 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_alarm_off));
        
        // 60진 업카운터(시간 셋팅용)
        counter_bcd_60  counter_sec( .clk(clk), .reset_p(reset_p), .clk_time(btn_sec), .bcd1(set_sec_1), .bcd10(set_sec_10));
        counter_bcd_60  counter_min( .clk(clk), .reset_p(reset_p), .clk_time(btn_min), .bcd1(set_min_1), .bcd10(set_min_10));
        
        // 60진 다운카운터(타이머 용)
        loadable_downcounter_bcd_60 cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(btn_start), 
                .load_bcd1(set_sec_1), .load_bcd10(set_sec_10), .bcd1(cur_sec_1), .bcd10(cur_sec_10), .dec_clk(dec_clk));   // 초시간 동기화
        loadable_downcounter_bcd_60 cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(btn_start), 
                .load_bcd1(set_min_1), .load_bcd10(set_min_10), .bcd1(cur_min_1), .bcd10(cur_min_10));
        
        // start_set 설정 
        assign cur_time = { cur_min_10, cur_min_1, cur_sec_10, cur_sec_1 };
        assign set_time = { set_min_10, set_min_1, set_sec_10, set_sec_1 };

        always @(posedge clk or posedge reset_p)begin
               if(reset_p)begin
                       start_set = 0;
                       alarm = 0;
               end
               else begin
                       if(btn_start)start_set = ~ start_set;
                       else if(cur_time == 0 && start_set)begin
                               start_set = 0;              // set 모드로 변경 
                               alarm = 1;                   // 시간이 다되면 알람이 켜져야 하므로
                       end
                       else if(btn_alarm_off) alarm = 0;
               end
        end       
        
        // 출력부 
        assign buzz = alarm;
        assign led_alarm = alarm;
        assign led_start = start_set;
        assign value = start_set ? cur_time : set_time;
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
                
endmodule

// keypad 
module keypad_test_top(
        input clk, reset_p,
        input [3:0] row,
        output [3:0] col,
        output [3:0] com,
        output [7:0] seg_7,
        output led_key_valid);

        wire [3:0] key_value;
        wire key_valid;
        keypad_cntrl_FSM   keypad( .clk(clk), .reset_p(reset_p), .row(row), .col(col),                   
            .key_value(key_value), .key_valid(key_valid));
        assign led_key_valid = key_valid;
        
        wire key_valid_p, key_valid_n;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(key_valid), .n_edge(key_valid_n), .p_edge(key_valid_p));                 
    
        reg [15:0] key_count;    
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)key_count = 0;
                else if(key_valid_p)begin
                        if(key_value == 1)key_count = key_count + 1;
                        else if(key_value == 2)key_count = key_count - 1;
                        else if(key_value == 3)key_count = key_count + 2;
                end
        end
            
       // fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value({12'b0, key_value}), .com(com), .seg_7(seg_7));
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(key_count), .com(com), .seg_7(seg_7));
        
        // seg_7 fnd에서 뒷 자리 1자리만 사용할 것이므로 나머지 value에 0 부여 
endmodule

//온습도 센서(dht11)
module  dht11_test_top(
        input clk,reset_p,
        inout dht11_data,
        output [15:0] led,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire [7:0] humidity, temperature;       // 온습도 데이터값 출력 
        dht11_cntrl( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));
        
        wire [15:0] humidity_bcd, temperature_bcd;  // 2진화 10진수 변환 
        bin_to_dec  bcd_humidity( .bin({4'b0, humidity}), .bcd(humidity_bcd));  // 총 12비트 중 8비트만 사용
        bin_to_dec  bcd_temperature( .bin({4'b0, temperature}), .bcd(temperature_bcd));
        
        wire [15:0] value;  // FND 출력
        assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};   
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
        
endmodule


// 초음파센서 (hcsr_04)
module  sr04_test_top(
        input clk, reset_p,
        input echo,
        output trig,
        output [15:0] led_debug,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire [21:0] distance_cm;
        SR04_cntrl(.clk(clk), .reset_p(reset_p), .trig(trig), .echo(echo), .distance_cm(distance_cm), .led_debug(led_debug));
        
        wire [15:0] distance_bcd;   // 2진화 10진수 변환 
        bin_to_dec  dis_bcd(.bin(distance_cm), .bcd(distance_bcd));
        
        wire [15:0] value;
        assign value = distance_bcd;        // FND 출력 
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
        
endmodule


// LED 밝기조절
module led_pwm_top(
        input clk, reset_p,
        output led_pwm);
        
        reg [31:0] clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        
        pwm_100step pwm_inst(.clk(clk), .reset_p(reset_p), .duty(clk_div[25:19]), .pwm(led_pwm));

endmodule

// RGB LED 
module rgbled_pwm_top(
        input clk, reset_p,
        output led_r, led_g, led_b);
        
        reg [31:0] clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        
        pwm_Nstep_freq #(.duty_step(77)) led_R(.clk(clk), .reset_p(reset_p), .duty(clk_div[26:20]), .pwm(led_r));
        pwm_Nstep_freq #(.duty_step(99)) led_G(.clk(clk), .reset_p(reset_p), .duty(clk_div[25:19]), .pwm(led_g));
        pwm_Nstep_freq #(.duty_step(103)) led_B(.clk(clk), .reset_p(reset_p), .duty(clk_div[27:21]), .pwm(led_b));

endmodule

// pwm DC motor
module dc_motor_pwm_top(
        input clk, reset_p,
        output motor_pwm,
        output [7:0] seg_7,
        output [3:0] com);
        
        reg [31:0] clk_div;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)clk_div = 0;
                else clk_div = clk_div + 1;
        end        
        
        wire clk_div_26_nedge;
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[26]), .n_edge(clk_div_26_nedge));   
        
        reg [5:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) duty = 10;
                else if(clk_div_26_nedge)begin
                        if(duty >= 99) duty = 10;
                        else duty = duty + 1;
                end
        end                      
        
        pwm_Nstep_freq #(.duty_step(100), .pwm_freq(100))
        pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(motor_pwm));

        wire [15:0] duty_bcd;  
        bin_to_dec  dis_bcd(.bin({6'b0, duty}), .bcd(duty_bcd));
        
        wire [15:0] value;
        assign value = duty_bcd;  
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
endmodule

//
// pwm servo motor
module servo_motor_pwm_top(
        input clk, reset_p,
        input [4:0] btn,
        output survo_pwm,
        output [7:0] seg_7,
        output [3:0] com);
        
//        reg [31:0] clk_div;
//        always @(posedge clk or posedge reset_p)begin
//                if(reset_p)clk_div = 0;
//                else clk_div = clk_div + 1;
//        end        
        wire btn_pwm;
        button_cntrl  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_M)); 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_L));
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_R)); 
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_set)); 
        
        reg [3:0] duty;
        reg [7:0] angle;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) begin duty = 3; angle = 0; end  // 초기값 설정 
                else if(btn_R) begin duty = 3; angle = 0; end   // 0도
                else if(btn_M) begin duty = 8; angle = 90; end  // 90도 
                else if(btn_L) begin duty = 12; angle = 180; end    // 180도
                else if(btn_set) begin  // 1단계씩 올리는 버튼
                        if(duty >= 12) duty = 3;
                        else duty = duty + 1;
                end
        end 
        
        pwm_Nstep_freq #(.duty_step(100), .pwm_freq(50))
                                      pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(survo_pwm));

        wire [15:0] duty_bcd;  
        bin_to_dec  dis_bcd(.bin({3'b0, angle}), .bcd(duty_bcd));   // 각도 FND 출력  
        
        wire [15:0] value;
        assign value = duty_bcd;  
        fnd_cntrl  fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
endmodule

// 자동 뱡향 전환 
module survo_motor_auto_top(
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output survo_pwm);

    reg [31:0] clk_div;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            clk_div = 0;
        else
            clk_div = clk_div + 1;
    end

    wire clk_div_24_nedge, btn_M;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[24]), .n_edge(clk_div_24_nedge));
    button_cntrl  btn_direction_change(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_M)); 

    reg [6:0] duty;       // duty 레지스터의 크기를 8비트로 설정
    reg down_up;        // down : 감소 up : 증가

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            duty = 12 ;       // 초기화 1ms (5% 듀티 사이클)
            down_up = 0;  // 초기 방향 설정 (0: 증가, 1: 감소)
        end
        else if (clk_div_24_nedge) begin // 20ms 주기
            if (!down_up) begin
                if (duty < 48)  // 2ms (10%)에 도달하지 않았다면 증가
                    duty = duty + 1;
                else
                    down_up = 1;  // 2ms에 도달하면 방향을 감소로 변경
            end
            else begin
                if (duty > 11)  // 1ms (5%)에 도달하지 않았다면 감소
                    duty = duty - 1;
                else
                    down_up = 0;  // 1ms에 도달하면 방향을 증가로 변경
            end
        end
        else if(btn_M) down_up = ~down_up;
    end

    pwm_Nstep_freq #(.duty_step(400),  .pwm_freq(50))
            pwm_motor( .clk(clk), .reset_p(reset_p), .duty(duty), .pwm(survo_pwm));

    wire [15:0] duty_bcd;
    bin_to_dec bcd_surbo( .bin({8'b0, duty}), .bcd(duty_bcd));

    fnd_cntrl   ( .clk(clk),  .reset_p(reset_p), .value(duty_bcd), .com(com), .seg_7(seg_7));

endmodule


module  adc_ch6_top(
        input clk, reset_p,
        input vauxp6, vauxn6,
        output [3:0] com,
        output [7:0] seg_7,
        output led_pwm);
        
        wire [4:0] channel_out;
        wire [15:0] do_out;
        wire eoc_out;
        
        xadc_wiz_0  adc_6
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out));             // End of Conversion Signal
            
         pwm_Nstep_freq #(.duty_step(200),  .pwm_freq(10000))
            pwm_backlight( .clk(clk), .reset_p(reset_p), .duty(do_out[15:8]), .pwm(led_pwm));

        wire [15:0] adc_value;
        bin_to_dec bcd_adc( .bin({2'b0, do_out[15:6]}), .bcd(adc_value));   // 10비트사용으로 해상도 손해대신 잡음 제외 안정적인 값 출력 
    
        fnd_cntrl   ( .clk(clk),  .reset_p(reset_p), .value(adc_value), .com(com), .seg_7(seg_7));

 endmodule


module adc_sequence2_top(
        input clk, reset_p,
        input vauxp6, vauxn6, vauxp15, vauxn15,
        output led_r, led_g,
        output [3:0] com,
        output [7:0] seg_7);

        wire [4:0] channel_out;
        wire [15:0] do_out;
        wire eoc_out;
        
        xadc_wiz_1  adc_seq2
              (
              .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
              .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
              .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
              .reset_in(reset_p),            // Reset signal for the System Monitor control logic
              .vauxp6(vauxp6),              // Auxiliary channel 6
              .vauxn6(vauxn6),
              .vauxp15(vauxp15),              // Auxiliary channel 6
              .vauxn15(vauxn15),
              .channel_out(channel_out),         // Channel Selection Outputs
              .do_out(do_out),              // Output data bus for dynamic reconfiguration port
              .eoc_out(eoc_out)              // End of Conversion Signal(변환 종료를 알림)
              );       

        wire eoc_out_pedge;
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));   

        reg [11:0] adc_value_x, adc_value_y;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        adc_value_x = 0;
                        adc_value_y = 0; 
                end
                else if(eoc_out_pedge)begin
                        case(channel_out[3:0])  // 최상위 1비트는 모드에 관한 비트이므로 하위 3비트만 사용 
                                6 : adc_value_x = do_out[15:4];
                                15 : adc_value_y = do_out[15:4];
                        endcase
                end
        end         

        pwm_Nstep_freq #(.duty_step(256),  .pwm_freq(10000))
            pwm_red( .clk(clk), .reset_p(reset_p), .duty(adc_value_x[11:4]), .pwm(led_r));
        pwm_Nstep_freq #(.duty_step(256),  .pwm_freq(10000))
            pwm_green( .clk(clk), .reset_p(reset_p), .duty(adc_value_y[11:4]), .pwm(led_g));
            
        wire [15:0] bcd_x, bcd_y, value;
        bin_to_dec bcd_adc_x( .bin({6'b0, adc_value_x[11:6]}), .bcd(bcd_x));
        bin_to_dec bcd_adc_y( .bin({6'b0, adc_value_y[11:6]}), .bcd(bcd_y));

        assign value = {bcd_x[7:0], bcd_y[7:0]};
        fnd_cntrl   ( .clk(clk),  .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
        
endmodule

module  i2c_master_top(
        input clk, reset_p,
        input [1:0] btn,
        output scl, sda,
        output [15:0] led);
        
        reg [7:0] data;
        reg comm_go;
        
        wire [1:0] btn_pedge;
        button_cntr  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_pedge[0]));                           // 채터링 문제 해결 
        button_cntr  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_pedge[1]));
        
        I2C_master( .clk(clk), .reset_p(reset_p),
                .addr(7'h27),     // datasheet 상 주소가 7'h27
                .rd_wr(0),              // write 만 = 0     
                .data(data),
                .comm_go(comm_go), 
                .scl(scl), .sda(sda),
                .led(led));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        data = 0;
                        comm_go = 0;
                end
                else begin
                        if(btn_pedge[0])begin       // 0번 버튼 누르면 data = 0 출력 
                              data = 8'b0000_0000;
                              comm_go = 1;  
                        end
                        else if(btn_pedge[1])begin      // 1번 버튼 누르면 data = 1 출력 
                                data = 8'b0000_1000;
                                comm_go = 1;  
                        end
                        else comm_go = 0;
                end
       end
endmodule

module i2c_txtlcd_top(
        input clk, reset_p,
        input [3:0] btn,
        output scl, sda,
        output [15:0] led);
        
        parameter   IDLE = 6'b00_0001;
        parameter   INIT = 6'b00_0010;
        parameter   SEND_DATA = 6'b00_0100;
        parameter   SEND_COMMAND = 6'b00_1000;
        parameter   SEND_MENTION1 = 6'b01_0000;
        parameter   SEND_MENTION2 = 6'b10_0000;
        
        wire [3:0] btn_pedge;
        button_cntr  btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_pedge[0]));                           // 채터링 문제 해결 
        button_cntr  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_pedge[1]));                           // 채터링 문제 해결 
        button_cntr  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_pedge[2]));                           // 채터링 문제 해결 
        button_cntr  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_pedge[3]));                           // 채터링 문제 해결 
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us         
        
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        reg [7:0] send_buffer;
        reg rs, send;
        wire busy;
        i2c_lcd_send_byte txtlcd( .clk(clk), .reset_p(reset_p),
                .addr(7'h27),
                .send_buffer(send_buffer),
                .rs(rs), .send(send),
                .scl(scl), .sda(sda),
                .busy(busy),
                .led(led));
        
        reg [5:0] state, next_state;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        reg init_flag;
        reg [3:0] count_data;
        reg [8*14-1:0] mention1;
        reg [8*15-1:0] mention2;
        reg [3:0] count_mention1, count_mention2;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        init_flag = 0;
                        count_data = 0;
                        count_usec_en = 0;
                        send = 0;
                        rs = 0;
                        mention1 = "ENTER PASSWORD";
                        mention2 = "PASSWORD ERROR!";
                        count_mention1 = 14;
                        count_mention2 = 15;
                end
                else begin
                        case(state)
                                IDLE : begin
                                        if(init_flag)begin
                                                    if(btn_pedge[0]) next_state = SEND_DATA;
                                                    if(btn_pedge[1]) next_state = SEND_COMMAND;
                                                    if(btn_pedge[2]) next_state = SEND_MENTION1;
                                                    if(btn_pedge[3]) next_state = SEND_MENTION2;
                                        end
                                        else begin
                                                if(count_usec <= 22'd80_000)begin
                                                        count_usec_en = 1;
                                                end
                                                else begin                 
                                                        next_state = INIT;
                                                        count_usec_en = 0;
                                                end            
                                        end
                                end
                                INIT : begin
                                        if(busy)begin           // 데이터 전송 시간동안 기다림
                                                send = 0;
                                                if(count_data >= 6)begin
                                                        next_state = IDLE;
                                                        init_flag = 1;
                                                        count_data = 0;
                                                end
                                        end                              // send == 0의 조건문을 넣어준 이유
                                        else if(!send)begin     // busy가 send의 상승엣지가 발생한 후에 1로 한 클럭 늦게 변하여 case 0 이 실행 X을 방지   
                                                case(count_data)
                                                        0 : send_buffer = 8'b0011_0011;
                                                        1 : send_buffer = 8'b0011_0010;
                                                        2 : send_buffer = 8'b0010_1000;        // N = 1 , F = 0
                                                        3 : send_buffer = 8'b0000_1100;         // Display On = 1, Cursor On = 1, Blinking Cursor On = 1
                                                        4 : send_buffer = 8'b0000_0001;        // Clear Display = 1
                                                        5 : send_buffer = 8'b0000_0110;        // Cursor Direction = 1 , Shift = 0
                                                endcase
                                                rs = 0;
                                                send = 1;
                                                count_data = count_data + 1;
                                        end
                                end
                                SEND_DATA : begin                       // DATA 전송
                                        if(busy)begin
                                                next_state = IDLE;
                                                send = 0;
                                                if(count_data >= 9) count_data = 0;
                                                else count_data = count_data + 1;        
                                        end
                                        else begin
                                                send_buffer = "0" + count_data;
                                                rs = 1;                 // Data : RS = 1
                                                send = 1;
                                        end
                                end
                                SEND_COMMAND : begin
                                        if(busy)begin
                                                next_state = IDLE;
                                                send = 0;
                                        end
                                       else begin
                                                send_buffer = 8'hC1;    // 8'b1100_0001 : Move to 2nd line 2nd space Cursor
                                                rs = 0;                             // Command : RS = 0
                                                send = 1;
                                        end
                                end
                                SEND_MENTION1 : begin
                                        if(busy)begin         
                                                send = 0;
                                                if(count_mention1 <= 0)begin
                                                        next_state = IDLE;
                                                        count_mention1 = 14;
                                                end
                                        end                           
                                        else if(!send)begin   
                                                case(count_mention1)
//                                                        16 : send_buffer = mention1[127:120];
//                                                        15 : send_buffer = mention1[119:112];
                                                        14 : send_buffer = mention1[111:104];      
                                                        13 : send_buffer = mention1[103:96];      
                                                        12 : send_buffer = mention1[95:88];    
                                                        11 : send_buffer = mention1[87:80];    
                                                        10 : send_buffer = mention1[79:72];    
                                                        9 : send_buffer = mention1[71:64];    
                                                        8 : send_buffer = mention1[63:56];    
                                                        7 : send_buffer = mention1[55:48];    
                                                        6 : send_buffer = mention1[47:40];    
                                                        5 : send_buffer = mention1[39:32];    
                                                        4 : send_buffer = mention1[31:24];    
                                                        3 : send_buffer = mention1[23:16];    
                                                        2 : send_buffer = mention1[15:8];    
                                                        1 : send_buffer = mention1[7:0];    
                                                endcase
                                                rs = 1;
                                                send = 1;
                                                count_mention1 = count_mention1 - 1;
                                        end
                                end
                                SEND_MENTION2 : begin
                                        if(busy)begin         
                                                send = 0;
                                                if(count_mention2 <= 0)begin
                                                        next_state = IDLE;
                                                        count_mention2 = 15;
                                                end
                                        end                           
                                        else if(!send)begin   
                                                case(count_mention1)
//                                                        16 : send_buffer = mention1[127:120];
                                                        15 : send_buffer = mention2[119:112];
                                                        14 : send_buffer = mention2[111:104];      
                                                        13 : send_buffer = mention2[103:96];      
                                                        12 : send_buffer = mention2[95:88];    
                                                        11 : send_buffer = mention2[87:80];    
                                                        10 : send_buffer = mention2[79:72];    
                                                        9 : send_buffer = mention2[71:64];    
                                                        8 : send_buffer = mention2[63:56];    
                                                        7 : send_buffer = mention2[55:48];    
                                                        6 : send_buffer = mention2[47:40];    
                                                        5 : send_buffer = mention2[39:32];    
                                                        4 : send_buffer = mention2[31:24];    
                                                        3 : send_buffer = mention2[23:16];    
                                                        2 : send_buffer = mention2[15:8];    
                                                        1 : send_buffer = mention2[7:0];    
                                                endcase
                                                rs = 1;
                                                send = 1;
                                                count_mention2 = count_mention2 - 1;
                                        end
                                end
                        endcase
                end         
        end
endmodule


