`timescale 1ns / 1ps

module HOMECURITY_TOP(
        input clk, reset_p,
        input pir_input,
        input vauxp6, vauxn6,  vauxp15, vauxn15,
        input [3:0] row,
        input btn_fan,
        input auto_switch, led_switch, switch_debug,
        input [15:0] led,
        inout dht11_data,
        output livingroom_led, standard_led, door_led,
        output buzz_flame, buzz_pir,
        output scl, sda,
        output [3:0] col,
        output motor_pwm, servo_pwm,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire [4:0] channel_out;
        wire [15:0] do_out;
        wire eoc_out;
        xadc_wiz_2  adc1
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),                    // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),             // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),              // Auxiliary channel 15
          .vauxn15(vauxn15),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out));             // End of Conversion Signal
          
        wire eoc_out_pedge;
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));   

        reg [11:0] adc_value_flame;
        reg [11:0] adc_value_cds;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        adc_value_flame = 0;
                        adc_value_cds = 0; 
                end
                else if(eoc_out_pedge)begin
                        case(channel_out[3:0])  // 최상위 1비트는 모드에 관한 비트이므로 하위 3비트만 사용 
                                15 : adc_value_cds = do_out[15:4];
                                6 : adc_value_flame = do_out[15:4];
                        endcase
                end
        end
        
        wire [15:0] cds_value, flame_value;     
        // 거실등
        livingroom_light    living( .clk(clk), .reset_p(reset_p), .auto_switch(auto_switch), .led_switch(led_switch), .adc_value_cds(adc_value_cds), 
                .livingroom_led(livingroom_led), .passive_led(standard_led), .cds_value(cds_value));
        // 온습도 센서(스마트모드)
        wire [15:0] dht11_value;
        dht11_fan_auto  fan_auto( .clk(clk),.reset_p(reset_p), .auto_switch(auto_switch), .dht11_data(dht11_data), .motor_pwm(motor_pwm), .value(dht11_value));
        // 불꽃 센서
        wire flame_flag;
        flame_sensor    flame( .clk(clk), .reset_p(reset_p), .adc_value_flame(adc_value_flame), .flame_value(flame_value),
            .servo_pwm(servo_pwm),  .flame_flag(flame_flag), .buzz_flame(buzz_flame));
        // 현관등 
        door_light  door( .clk(clk), .reset_p(reset_p), .pir_input(pir_input), .door_led(door_led));
        // 인체감지센서 + 부저(방범모드)
        wire pir_flag;
        security_pir sc_pir( .clk(clk), .reset_p(reset_p), .pir_input(pir_input), .security_on(security_on), .pir_flag(pir_flag), .buzz_pir(buzz_pir));
        // 도어락
        wire wrong3_flag, security_flag, open_flag;
        doorlock_keypad     doorlock( .clk(clk), .reset_p(reset_p), .row(row), .col(col), .sda(sda), .scl(scl), 
                .wrong3_flag(wrong3_flag), .security_flag(security_flag), .open_flag(open_flag));
        
        // 외부 LCD 출력 문구
        i2c_txtlcd_external external( .clk(clk), .reset_p(reset_p), .flame_flag(flame_flag), .pir_flag(pir_flag), .scl(scl), .sda(sda));
        // FND 출력
        wire [15:0] fnd_value;
        assign fnd_value = (switch_debug) ? cds_value : flame_value;
        fnd_cntr  fnd(.clk(clk), .reset_p(reset_p), .value(fnd_value), .com(com), .seg_7(seg_7));
        
endmodule