`timescale 1ns / 1ps

module HOMECURITY_TOP(
        input clk, reset_p,
        input pir_input,
        input vauxp6, vauxn6,  vauxp15, vauxn15,
        input [3:0] row,
        input btn_fan,
        input smart_switch, led_switch, switch_debug,
        output [2:0] led,
        inout dht11_data,
        output livingroom_led, standard_led, door_led,
        output buzz_flame, buzz_pir, buzz_wrong3,
        output scl_external, sda_external, scl_doorlock, sda_doorlock,
        output [3:0] col,
        output dc_fan, servo_window, servo_door,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire [4:0] channel_out;
        wire [15:0] do_out;
        wire eoc_out;
        xadc_wiz_2  adc1
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),                        // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),                 // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),                // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),                  // Auxiliary channel 6
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),               // Auxiliary channel 15
          .vauxn15(vauxn15),
          .channel_out(channel_out),    // Channel Selection Outputs
          .do_out(do_out),                   // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out));              // End of Conversion Signal
          
        wire eoc_out_pedge;
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));   

        reg [11:0] adc_value_flame, adc_value_cds;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        adc_value_flame = 0;
                        adc_value_cds = 0; 
                end
                else if(eoc_out_pedge)begin
                        case(channel_out[3:0]) 
                                15 : adc_value_cds = do_out[15:4];      // 조도센서 값
                                6 : adc_value_flame = do_out[15:4];     // 불꽃센서 값
                        endcase
                end
        end
        
        wire [15:0] cds_value, flame_value;     
        // 자동 조명 시스템(조도센서 + LED)
        livingroom_light    living( .clk(clk), .reset_p(reset_p), .smart_switch(smart_switch), .led_switch(led_switch), .adc_value_cds(adc_value_cds), 
                .livingroom_led(livingroom_led), .standard_led(standard_led), .cds_value(cds_value));
        // 현관등(인체감지센서)
        door_light  door( .clk(clk), .reset_p(reset_p), .pir_input(pir_input), .door_led(door_led));
        
        // 자동 냉방 시스템(dht11 + DC)
        wire [15:0] dht11_value;
        dht11_fan_smart  fan_smart( .clk(clk),.reset_p(reset_p), .smart_switch(smart_switch), .dht11_data(dht11_data), .motor_pwm(motor_pwm_smart), .value(dht11_value));
        dc_motor_fan_standard   fan_standard( .clk(clk), .reset_p(reset_p), .btn_fan(btn_fan), .motor_pwm(motor_pwm_standard), .led(led));
        assign dc_fan = (smart_switch) ? motor_pwm_smart : motor_pwm_standard;
        // 실내 온/습도 FND 출력 
        fnd_cntr  fnd(.clk(clk), .reset_p(reset_p), .value(dht11_value), .com(com), .seg_7(seg_7));
        
        // 화재 경보 시스템(불꽃센서)
        wire flame_flag;
        flame_sensor    flame( .clk(clk), .reset_p(reset_p), .adc_value_flame(adc_value_flame), .flame_value(flame_value),
            .servo_pwm(servo_window),  .flame_flag(flame_flag), .buzz_flame(buzz_flame));
            
        // 방범 시스템(인체감지센서 + 부저 + LCD)
        wire pir_flag, security_flag, open_flag;
        security_pir sc_pir( .clk(clk), .reset_p(reset_p), .pir_input(pir_input), .security_on(security_flag), .pir_flag(pir_flag), .buzz_pir(buzz_pir));
        
        // 도어락(키패드)
        doorlock_keypad     doorlock( .clk(clk), .reset_p(reset_p), .row(row), .col(col), .sda(sda_doorlock), .scl(scl_doorlock), 
                .wrong3_flag(buzz_wrong3), .security_flag(security_flag), .open_flag(open_flag));
        // 도어락(문)
        servo_motor_door    servo1( .clk(clk), .reset_p(reset_p), .open_flag(open_flag), .flame_flag(flame_flag), .servo_door(servo_door));
        
        // 외부 LCD 출력 문구(화재경보 + 침입감지)
        i2c_txtlcd_external external( .clk(clk), .reset_p(reset_p), .security_on(security_flag),.flame_flag(flame_flag), .pir_flag(pir_flag), .scl(scl_external), .sda(sda_external));
        
endmodule