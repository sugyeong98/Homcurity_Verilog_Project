`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module doorlock_keypad(
            input clk, reset_p,
            input [3:0] row,
            input [3:0] btn,
            output sda, scl,
            output [15:1] led_debug,
            output [3:0] col,
            output [3:0] com,
            output [7:0] seg_7,
            output led_key_valid,
            output reg wrong3_flag,
            output reg security_flag,
            output reg open_flag
            );
    
        wire [3:0] key_value;
        wire key_valid;
        keypad_cntr_FSM      keypad       (.clk(clk), .reset_p(reset_p), .row(row), .col(col), .key_value(key_value), .key_valid(key_valid));

        wire [15:0]value;
        assign value = pw_fnd ? (pw_enpw ? password : entered_password) : {12'b0, key_value};
        fnd_cntr               fnd             (.clk(clk), .reset_p(reset_p), .value(value), .com(com),  .seg_7(seg_7));
        
        parameter IDLE = 8'b0000_0001;
        parameter INIT = 8'b0000_0010;  //초기화하는 과정, 처음에 한번만 초기화하면 됨
        parameter SET_PASSWORD = 8'b0000_0100;
        parameter SEND_PASSWORD = 8'b0000_1000;
        parameter LCD_CLEAR = 8'b0001_0000;
        parameter ENTER_PASSWORD = 8'b0010_0000;
        parameter COMPLETE_PASSWORD = 8'b0100_0000;
        parameter SECURITY_MODE = 8'b1000_0000;
        

        wire clk_usec, clk_usec_1;
        clock_div_100    usec_clock  (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec)); 
        clock_div_100    usec_clock_1  (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec_1)); 
        
        reg [21:0] count_usec;  
        reg count_usec_e;      
            always @(negedge clk or posedge reset_p) begin
                        if(reset_p) count_usec = 0;
                        else if(clk_usec && count_usec_e)count_usec = count_usec+1;
                        else if(!count_usec_e) count_usec =0;
             end         
             
        reg [21:0] count_usec_1;  
        reg count_usec_e_1;
            always @(negedge clk or posedge reset_p) begin
                        if(reset_p) count_usec_1 = 0;
                        else if(clk_usec_1 && count_usec_e_1)count_usec_1 = count_usec_1+1;
                        else if(!count_usec_e_1) count_usec_1 =0;
             end 

        wire key_valid_pedge;
        button_cntr         key(.clk(clk), .reset_p(reset_p), .btn(key_valid), .btn_pedge(key_valid_pedge));
        
        reg [7:0] send_buffer;
        reg rs, send;        
        wire busy;
        i2c_lcd_send_byte( .clk(clk), .reset_p(reset_p), .addr(7'h27),.send_buffer(send_buffer), .rs(rs), .send(send) ,.scl(scl), .sda(sda),.busy(busy), .led(led_debug)); 
        
        reg [7:0] state, next_state;
        always @(negedge clk or posedge reset_p) begin
                if(reset_p) state = IDLE;
                else state = next_state;                
        end
        
        reg init_flag, pre_wrong3_flag, not_flag;
        reg [4:0] cnt_data,  cnt_pw, cnt_pw_1,cnt_pw_2, cnt_clear, cnt_clear_1, cnt_wrong, cnt_wrong_1;
        reg [4:0] cnt_string_1, cnt_string_2, cnt_string_3, cnt_string_4, cnt_string_5, cnt_string_6, cnt_string_7, cnt_string_8, cnt_string_9, cnt_string_10;
        reg [4:0] cnt_string_a, cnt_string_b, cnt_string_c, cnt_string_d, cnt_string_e;
        reg [71:0] set_pw;
        reg [63:0]complete_pw;
        reg [87:0] enter_pw;
        reg [95:0]correct;
        reg [111:0] wrong;  
        reg [71:0] warning;
        reg [87:0] security_on;      
        reg [95:0] security_off;
        reg [15:0] password, entered_password, security_password;
        reg pw_fnd, pw_enpw, pre_wrong3_flag_1;
        reg set_complete, enter_complete, start_setting, start_entering, security_pw, security_complete;
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                        next_state = IDLE;
                        count_usec_e =0; count_usec_e_1 =0;
                        init_flag =0; not_flag =0; security_flag =0; open_flag =0; 
                        rs =0;
                        send =0;
                        pw_fnd =0; pw_enpw =0;
                        set_pw = "SET PW : ";
                        complete_pw = "COMPLETE";
                        enter_pw = "ENTER PW : ";
                        correct = "WELCOME HOME";
                        wrong = "WRONG PW  LEFT";
                        warning = "WARNING!!";
                        security_on = "SECURITY ON";
                        security_off = "SECURITY OFF";
                        set_complete =0; enter_complete =0; security_complete =0;
                        start_setting =0; start_entering =0;
                        cnt_data = 0;
                        cnt_string_1 =0; cnt_string_2 =0; cnt_string_3 =0; cnt_string_4 =0; cnt_string_5 =0;
                        cnt_string_6 =0; cnt_string_7 =0; cnt_string_8 =0; cnt_string_9 =0; cnt_string_10 =0;
                        cnt_string_a =0; cnt_string_b =0; cnt_string_c =0; cnt_string_d =0; cnt_string_e =0;
                        cnt_clear =0; cnt_clear_1 =0;
                        cnt_pw =0; cnt_pw_1 =0; cnt_pw_2=0;
                        cnt_wrong =0; cnt_wrong_1 =0;
                        wrong3_flag =0; pre_wrong3_flag =0; pre_wrong3_flag_1 =0;                        
                        password =0; entered_password =0; security_password =0;                  
                        security_pw =0;
                end
                else begin
                        case(state)
                                IDLE : begin
                                        if(init_flag) begin
                                                if(key_valid_pedge)begin
                                                        if(key_value >=4'h0 &&  key_value<=4'h9) next_state = SEND_PASSWORD;
                                                        else if(key_value == 4'ha)next_state = SET_PASSWORD;
                                                        else if(key_value == 4'hb)next_state = ENTER_PASSWORD;
                                                        else if(key_value == 4'he)next_state = COMPLETE_PASSWORD;
                                                        else if(key_value == 4'hd)next_state = SECURITY_MODE;
                                                        else next_state = IDLE;
                                                 end
                                        end
                                        else begin
                                                if(count_usec <= 22'd80_000)begin //15_000만 기다려도된다고 데이터시트에는 나와있음
                                                        count_usec_e =1;
                                                end
                                                else begin  
                                                        next_state = INIT;
                                                        count_usec_e =0;
                                                end
                                        end
                                end
                                
                                INIT : begin
                                        if(busy) begin
                                                 send =0;
                                                 if(cnt_data >= 6)begin
                                                        next_state = IDLE;
                                                        init_flag =1;
                                                        cnt_data =0;
                                                        rs =0;
                                                 end
                                        end
                                        else if (!send)begin
                                                case(cnt_data)
                                                        0 :  send_buffer = 8'h33;
                                                        1 :  send_buffer = 8'h32;   //여기까지가 초기화,,?
                                                        2 :  send_buffer = 8'h28;
                                                        3 :  send_buffer = 8'h0f;
                                                        4 :  send_buffer = 8'h01;
                                                        5 :  send_buffer = 8'h06;
                                                endcase
                                                rs =0;
                                                send =1; // 엣지를 감지하기에 
                                                cnt_data = cnt_data + 1;
                                        end
                                end
                                
                                SET_PASSWORD : begin
                                          if(busy) begin
                                                 send =0;
                                                 if(cnt_string_1 >= 9)begin
                                                        next_state = IDLE;
                                                        cnt_string_1 =0;
                                                        start_setting =1;
                                                        password =0;
                                                 end
                                                 if(cnt_string_2 >= 9)begin
                                                        next_state = LCD_CLEAR;
                                                        cnt_string_2 =0;
                                                        set_complete =0;
                                                        start_setting =0;
                                                 end
                                        end
                                        else if (!send)begin                                               
                                                if(!set_complete)begin
                                                        case(cnt_string_1)
                                                                0 : begin send_buffer = set_pw[71 : 64]; rs =1; end
                                                                1 : begin send_buffer = set_pw[63 : 56]; rs =1; end
                                                                2 : begin send_buffer = set_pw[55 : 48]; rs =1; end
                                                                3 : begin send_buffer = set_pw[47 : 40]; rs =1; end
                                                                4 :  begin send_buffer = set_pw[39 : 32]; rs =1; end
                                                                5 :  begin send_buffer = set_pw[31 : 24]; rs =1; end
                                                                6 :  begin send_buffer = set_pw[23 : 16]; rs =1; end
                                                                7 :  begin send_buffer = set_pw[15 : 8]; rs =1; end
                                                                8 :  begin send_buffer = set_pw[7: 0]; rs =1; end
                                                        endcase
                                                        send =1; // 엣지를 감지하기에 
                                                        cnt_string_1 = cnt_string_1 + 1;        
                                                end
                                                else begin
                                                         case(cnt_string_2)
                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                1 : begin send_buffer = complete_pw[63 : 56]; rs =1; end
                                                                2 : begin send_buffer = complete_pw[55 : 48]; rs =1; end
                                                                3 : begin send_buffer = complete_pw[47 : 40]; rs =1; end
                                                                4 : begin send_buffer = complete_pw[39 : 32]; rs =1; end
                                                                5 : begin send_buffer = complete_pw[31 : 24]; rs =1; end
                                                                6 : begin send_buffer = complete_pw[23 : 16]; rs =1; end
                                                                7 : begin send_buffer = complete_pw[15 : 8]; rs =1; end
                                                                8 : begin send_buffer = complete_pw[7: 0]; rs =1; end
                                                        endcase
                                                        pw_fnd =1; pw_enpw =1;
                                                        send =1; 
                                                        cnt_string_2 = cnt_string_2 + 1;        
                                                end
                                        end
                                end
                                
                                SEND_PASSWORD: begin
                                        if(busy) begin
                                                send =0;
                                                next_state = IDLE;
                                                
                                                if(cnt_pw >3)begin
                                                        cnt_pw =0;
                                                        next_state = IDLE;
                                                        start_setting =0;
                                                end
                                                
                                                if(cnt_pw_1 >3)begin
                                                        cnt_pw_1 =0;
                                                        next_state = IDLE;
                                                end
                                                
                                                if(cnt_pw_2 >3)begin
                                                        cnt_pw_2 =0;
                                                        next_state = IDLE;
                                                        security_complete = 1;
                                                end
                                                
                                        end
                                        else if(!send) begin
                                                send_buffer = "*";
                                                rs =1; //데이터를 보낼 경우에는 rs 1
                                                send =1;
                                                pw_fnd =0;
                                                if(start_setting) begin
                                                        case(cnt_pw)
                                                                0 : password[15:12] = key_value;
                                                                1 : password[11:8] = key_value;
                                                                2 : password[7:4] = key_value;
                                                                3 : begin 
                                                                      password[3:0] = key_value;                                                     
                                                                      set_complete =1;
                                                                      end
                                                        endcase
                                                        cnt_pw = cnt_pw+1;
                                                end
                                                
                                                if(start_entering) begin
                                                        case(cnt_pw_1)
                                                                0 : entered_password[15:12] = key_value;
                                                                1 : entered_password[11:8] = key_value;
                                                                2 : entered_password[7:4] = key_value;
                                                                3 : begin
                                                                        entered_password[3:0] = key_value;
                                                                        enter_complete = 1;
                                                                end
                                                        endcase
                                                        cnt_pw_1 = cnt_pw_1+1;
                                                end
                                                
                                                if(security_flag) begin                                                        
                                                        case(cnt_pw_2)
                                                                0 : security_password[15:12] = key_value;
                                                                1 : security_password[11:8] = key_value;
                                                                2 : security_password[7:4] = key_value;
                                                                3 : security_password[3:0] = key_value;
                                                        endcase
                                                        cnt_pw_2 = cnt_pw_2+1;
                                                end
                                        end                              
                                end
                                
                                LCD_CLEAR : begin
                                         if(busy) begin
                                                send =0;
                                                 if(cnt_clear >= 2)begin
                                                        next_state = IDLE;
                                                        cnt_clear =0;
                                                        count_usec_e =0;
                                                        count_usec_e_1 =0;       
                                                 end                                                 
                                        end
                                        else if (!send)begin 
                                                         if(count_usec <= 22'd2_000_000)begin
                                                                 count_usec_e =1;
                                                        end
                                                        else  begin
                                                                case(cnt_clear)
                                                                        0 : begin  send_buffer = 8'h01; rs =0;end
                                                                        1 : begin
                                                                                if(count_usec_1 <= 22'd300_000)begin
                                                                                        count_usec_e_1 =1;
                                                                                end       
                                                                        end                                                                
                                                                endcase
                                                                send =1;    
                                                                cnt_clear = cnt_clear+1;                                        
                                                        end 
                                                 end  
                                        end
                                
                                ENTER_PASSWORD : begin
                                        if(busy) begin
                                                 send =0;
                                                 if(cnt_string_3 >= 11)begin
                                                        next_state = IDLE;
                                                        cnt_string_3 =0;
                                                        start_entering =1;
                                                 end
                                                 if(cnt_string_10 >= 11)begin
                                                        next_state = IDLE;
                                                        cnt_string_10 =0;
                                                        start_entering =1;
                                                 end
                                                 if(cnt_string_9 >= 12)begin
                                                        next_state = IDLE;
                                                        cnt_string_9 =0;
                                                 end
                                                  if(cnt_string_e >= 18)begin
                                                        next_state = IDLE;
                                                        cnt_string_e =0;
                                                        count_usec_e =0;
                                                        count_usec_e_1 =0; 
                                                 end
                                        end
                                        else if (!send)begin
                                                        if(!security_flag) begin
                                                        case(cnt_string_10)
                                                                0 : begin send_buffer = enter_pw[87 : 80]; rs =1; end
                                                                1 : begin send_buffer = enter_pw[79 : 72]; rs =1; end
                                                                2 : begin send_buffer = enter_pw[71 : 64]; rs =1; end
                                                                3 : begin send_buffer = enter_pw[63 : 56]; rs =1; end
                                                                4 : begin send_buffer = enter_pw[55 : 48]; rs =1; end
                                                                5 : begin send_buffer = enter_pw[47 : 40]; rs =1; end
                                                                6 :  begin send_buffer = enter_pw[39 : 32]; rs =1; end
                                                                7 :  begin send_buffer = enter_pw[31 : 24]; rs =1; end
                                                                8 :  begin send_buffer = enter_pw[23 : 16]; rs =1; end
                                                                9 :  begin send_buffer = enter_pw[15 : 8]; rs =1; end
                                                                10 :  begin send_buffer = enter_pw[7: 0]; rs =1; end
                                                        endcase
                                                                send =1; // 엣지를 감지하기에 
                                                                cnt_string_10 = cnt_string_10 + 1;
                                                        end
                                                        
                                                        if(security_flag)begin
                                                                if(!cnt_wrong_1)begin
                                                                        case(cnt_string_9)
                                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                1 : begin send_buffer = enter_pw[87 : 80]; rs =1; end
                                                                                2 : begin send_buffer = enter_pw[79 : 72]; rs =1; end
                                                                                3 : begin send_buffer = enter_pw[71 : 64]; rs =1; end
                                                                                4 : begin send_buffer = enter_pw[63 : 56]; rs =1; end
                                                                                5 : begin send_buffer = enter_pw[55 : 48]; rs =1; end
                                                                                6 : begin send_buffer = enter_pw[47 : 40]; rs =1; end
                                                                                7 :  begin send_buffer = enter_pw[39 : 32]; rs =1; end
                                                                                8 :  begin send_buffer = enter_pw[31 : 24]; rs =1; end
                                                                                9 :  begin send_buffer = enter_pw[23 : 16]; rs =1; end
                                                                                10 :  begin send_buffer = enter_pw[15 : 8]; rs =1; end
                                                                                11 :  begin send_buffer = enter_pw[7: 0]; rs =1; end
                                                                        endcase
                                                                                send =1; // 엣지를 감지하기에 
                                                                                cnt_string_9 = cnt_string_9 + 1;
                                                                        end
                                                                end
                                                                
                                                                  if(cnt_wrong_1)begin
                                                                         if(count_usec <= 22'd2_000_000)begin
                                                                                 count_usec_e =1;
                                                                         end
                                                                         else begin
                                                                                 case(cnt_string_e)
                                                                                        0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                        1 : begin send_buffer = enter_pw[87 : 80]; rs =1; end
                                                                                        2 : begin send_buffer = enter_pw[79 : 72]; rs =1; end
                                                                                        3 : begin send_buffer = enter_pw[71 : 64]; rs =1; end
                                                                                        4 : begin send_buffer = enter_pw[63 : 56]; rs =1; end
                                                                                        5 : begin send_buffer = enter_pw[55 : 48]; rs =1; end
                                                                                        6 : begin send_buffer = enter_pw[47 : 40]; rs =1; end
                                                                                        7 :  begin send_buffer = enter_pw[39 : 32]; rs =1; end
                                                                                        8 :  begin send_buffer = enter_pw[31 : 24]; rs =1; end
                                                                                        9 :  begin send_buffer = enter_pw[23 : 16]; rs =1; end
                                                                                        10 :  begin send_buffer = enter_pw[15 : 8]; rs =1; end
                                                                                        11 :  begin send_buffer = enter_pw[7: 0]; rs =1; end
                                                                                        10 : begin send_buffer = " "; rs =1; end
                                                                                        11 : begin send_buffer = " "; rs =1; end
                                                                                        12 : begin send_buffer = " "; rs =1; end
                                                                                        13 : begin send_buffer = " "; rs =1; end
                                                                                        14 : begin send_buffer = " "; rs =1; end
                                                                                        15 : begin send_buffer = " "; rs =1; end
                                                                                        15 : begin send_buffer = 8'hcb;  rs =0; end
                                                                                        16 : begin 
                                                                                                 if(count_usec_1 <= 22'd300_000)begin
                                                                                                        count_usec_e_1 =1;
                                                                                                end
                                                                                        end
                                                                                        17 : begin send_buffer = 8'hcb;  rs =0; end
                                                                                endcase
                                                                                send =1; // 엣지를 감지하기에 
                                                                                cnt_string_e = cnt_string_e + 1;
                                                                        end
                                                                end
                                        end
                                end
                                
                                COMPLETE_PASSWORD : begin
                                        if(busy) begin
                                                 send =0;
                                                 if(cnt_string_4 >= 13)begin
                                                        next_state = LCD_CLEAR;
                                                        cnt_string_4 =0;
                                                        start_entering =0;
                                                        cnt_wrong =0;
                                                        open_flag =1;
                                                 end
                                                  if(cnt_string_5 >= 15)begin
                                                        next_state = LCD_CLEAR;
                                                        cnt_string_5 =0;
                                                        cnt_wrong = cnt_wrong +1;
                                                        start_entering =0;
                                                 end                                                
                                                 if(cnt_string_6 >= 10)begin
                                                        next_state = IDLE;
                                                        cnt_string_6 =0;  
                                                        cnt_wrong = cnt_wrong +1;
                                                        start_entering =0;                                                      
                                                 end  
                                                 if(cnt_wrong == 2) begin
                                                        pre_wrong3_flag =1;
                                                 end
                                                 if(cnt_wrong >= 3)begin
                                                        next_state = IDLE;
                                                        cnt_wrong =0;
                                                        wrong3_flag =1;
                                                 end
                                                 if(not_flag)begin
                                                        next_state = IDLE;
                                                        not_flag =0;
                                                 end                          
                                                 pw_fnd =1; pw_enpw =0;
                                        end
                                        
                                        else if (!send)begin
                                                if(start_entering) begin                                            
                                                        if(entered_password == password)begin
                                                                case(cnt_string_4)
                                                                        0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                        1 : begin send_buffer = correct[95 : 88]; rs =1; end
                                                                        2 : begin send_buffer = correct[87 : 80]; rs =1; end
                                                                        3 : begin send_buffer = correct[79 : 72]; rs =1; end
                                                                        4 : begin send_buffer = correct[71 : 64]; rs =1; end
                                                                        5 : begin send_buffer = correct[63 : 56]; rs =1; end
                                                                        6 : begin send_buffer = correct[55 : 48]; rs =1; end
                                                                        7 : begin send_buffer = correct[47 : 40]; rs =1; end
                                                                        8 :  begin send_buffer = correct[39 : 32]; rs =1; end
                                                                        9 :  begin send_buffer = correct[31 : 24]; rs =1; end
                                                                        10 :  begin send_buffer = correct[23 : 16]; rs =1; end
                                                                        11 :  begin send_buffer = correct[15 : 8]; rs =1; end
                                                                        12 :  begin send_buffer = correct[7: 0]; rs =1; end
                                                                endcase
                                                                send =1; 
                                                                cnt_string_4 = cnt_string_4 + 1;        
                                                        end
                                                        
                                                        if(entered_password != password)begin
                                                                if(pre_wrong3_flag)begin
                                                                        case(cnt_string_6)
                                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                1 : begin send_buffer = warning[71 : 64]; rs =1; end
                                                                                2 : begin send_buffer = warning[63 : 56]; rs =1; end
                                                                                3 : begin send_buffer = warning[55 : 48]; rs =1; end
                                                                                4 : begin send_buffer = warning[47 : 40]; rs =1; end
                                                                                5 :  begin send_buffer = warning[39 : 32]; rs =1; end
                                                                                6 :  begin send_buffer = warning[31 : 24]; rs =1; end
                                                                                7 :  begin send_buffer = warning[23 : 16]; rs =1; end
                                                                                8 :  begin send_buffer = warning[15 : 8]; rs =1; end
                                                                                9 :  begin send_buffer = warning[7: 0]; rs =1; end
                                                                        endcase
                                                                        send =1; 
                                                                        cnt_string_6 = cnt_string_6 + 1;
                                                                end
                                                                else begin
                                                                        case(cnt_string_5)
                                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                1 : begin send_buffer = wrong[111 : 104]; rs =1; end
                                                                                2 : begin send_buffer = wrong[103 : 96]; rs =1; end
                                                                                3 : begin send_buffer = wrong[95 : 88]; rs =1; end
                                                                                4 : begin send_buffer = wrong[87 : 80]; rs =1; end
                                                                                5 : begin send_buffer = wrong[79 : 72]; rs =1; end
                                                                                6 : begin send_buffer = wrong[71 : 64]; rs =1; end
                                                                                7: begin send_buffer = wrong[63 : 56]; rs =1; end
                                                                                8 : begin send_buffer = wrong[55 : 48]; rs =1; end
                                                                                9 : begin send_buffer = wrong[47 : 40]; rs =1; end
                                                                                10 :  begin send_buffer =  "2"- cnt_wrong;  rs =1; end
                                                                                11 :  begin send_buffer = wrong[31 : 24]; rs =1; end
                                                                                12 :  begin send_buffer = wrong[23 : 16]; rs =1; end
                                                                                13 :  begin send_buffer = wrong[15 : 8]; rs =1; end
                                                                                14 :  begin send_buffer = wrong[7: 0]; rs =1; end
                                                                            endcase
                                                                            send =1; 
                                                                            cnt_string_5 = cnt_string_5 + 1;            
                                                                end                                             
                                                        end
                                                 end
                                                 else if(!start_entering) begin
                                                         send_buffer = 8'h00;  rs =0;
                                                         send =1;
                                                         not_flag =1;
                                                 end                                                                               
                                        end                                        
                                end
                                
                                SECURITY_MODE : begin                                
                                         if(busy) begin
                                                 send =0;
                                                 if(cnt_string_7 >= 11)begin
                                                        next_state = IDLE;
                                                        cnt_string_7 =0;
                                                        security_flag =1;
                                                 end
                                                 if(cnt_string_a >= 16)begin
                                                        next_state = LCD_CLEAR;
                                                        cnt_string_a =0;
                                                        security_flag =0;
                                                        security_complete =0;
                                                        cnt_wrong =0;
                                                 end
                                                 if(cnt_string_c >= 1)begin
                                                        next_state = ENTER_PASSWORD;
                                                        cnt_string_c =0;
                                                 end
                                                 if(cnt_string_d >= 16)begin
                                                        next_state = ENTER_PASSWORD;
                                                        cnt_string_d =0;
                                                        cnt_wrong_1 = cnt_wrong_1 +1;
                                                 end                                                
                                                 if(cnt_string_b >= 16)begin
                                                        next_state = IDLE;
                                                        cnt_string_b =0;  
                                                        cnt_wrong_1 = cnt_wrong_1 +1;                                                  
                                                 end  
                                                 if(cnt_wrong_1 == 2) begin
                                                        pre_wrong3_flag_1 =1;
                                                 end
                                                 if(cnt_wrong_1 >= 3)begin
                                                        next_state = IDLE;
                                                        cnt_wrong_1 =0;
                                                        wrong3_flag =1;
                                                 end              
                                        end
                                        else if (!send)begin
                                                        if(!security_flag && !security_complete) begin;   
                                                                case(cnt_string_7)
                                                                        0 : begin send_buffer = security_on[87 : 80]; rs =1; end
                                                                        1 : begin send_buffer = security_on[79 : 72]; rs =1; end
                                                                        2 : begin send_buffer = security_on[71 : 64]; rs =1; end
                                                                        3 : begin send_buffer = security_on[63 : 56]; rs =1; end
                                                                        4 : begin send_buffer = security_on[55 : 48]; rs =1; end
                                                                        5 : begin send_buffer = security_on[47 : 40]; rs =1; end
                                                                        6 :  begin send_buffer = security_on[39 : 32]; rs =1; end
                                                                        7 :  begin send_buffer = security_on[31 : 24]; rs =1; end
                                                                        8 :  begin send_buffer = security_on[23 : 16]; rs =1; end
                                                                        9 :  begin send_buffer = security_on[15 : 8]; rs =1; end
                                                                        10 :  begin send_buffer = security_on[7: 0]; rs =1; end
                                                                endcase
                                                                send =1; // 엣지를 감지하기에 
                                                                cnt_string_7 = cnt_string_7 + 1;
                                                        end
                                                        
                                                        if(security_flag && !security_complete) begin;                                                     
                                                                 case(cnt_string_c)
                                                                         0: begin send_buffer =" "; rs =1;end
                                                                 endcase
                                                                 send =1; 
                                                                 cnt_string_c = cnt_string_c+1;
                                                        end
                                                        
                                                        if(security_flag && security_complete)begin
                                                                 if(security_password == password)begin
                                                                        case(cnt_string_a)
                                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                1 : begin send_buffer = security_off[95 : 88]; rs =1; end
                                                                                2 : begin send_buffer = security_off[87 : 80]; rs =1; end
                                                                                3 : begin send_buffer = security_off[79 : 72]; rs =1; end
                                                                                4 : begin send_buffer = security_off[71 : 64]; rs =1; end
                                                                                5 : begin send_buffer = security_off[63 : 56]; rs =1; end
                                                                                6 : begin send_buffer = security_off[55 : 48]; rs =1; end
                                                                                7 : begin send_buffer = security_off[47 : 40]; rs =1; end
                                                                                8 :  begin send_buffer = security_off[39 : 32]; rs =1; end
                                                                                9 :  begin send_buffer = security_off[31 : 24]; rs =1; end
                                                                                10 :  begin send_buffer = security_off[23 : 16]; rs =1; end
                                                                                11 :  begin send_buffer = security_off[15 : 8]; rs =1; end
                                                                                12 :  begin send_buffer = security_off[7: 0]; rs =1; end
                                                                                13: begin send_buffer = " "; rs =1; end
                                                                                14: begin send_buffer = " "; rs =1; end
                                                                                15: begin send_buffer = " "; rs =1; end
                                                                        endcase
                                                                        send =1; 
                                                                        cnt_string_a = cnt_string_a + 1;        
                                                                  end
                                                        
                                                                  if(security_password != password)begin
                                                                         if(pre_wrong3_flag_1)begin
                                                                        case(cnt_string_b)
                                                                                0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                1 : begin send_buffer = warning[71 : 64]; rs =1; end
                                                                                2 : begin send_buffer = warning[63 : 56]; rs =1; end
                                                                                3 : begin send_buffer = warning[55 : 48]; rs =1; end
                                                                                4 : begin send_buffer = warning[47 : 40]; rs =1; end
                                                                                5 :  begin send_buffer = warning[39 : 32]; rs =1; end
                                                                                6 :  begin send_buffer = warning[31 : 24]; rs =1; end
                                                                                7 :  begin send_buffer = warning[23 : 16]; rs =1; end
                                                                                8 :  begin send_buffer = warning[15 : 8]; rs =1; end
                                                                                9 :  begin send_buffer = warning[7: 0]; rs =1; end
                                                                                10 : begin send_buffer = " "; rs =1; end
                                                                                11 : begin send_buffer = " "; rs =1; end
                                                                                12 : begin send_buffer = " "; rs =1; end
                                                                                13 : begin send_buffer = " "; rs =1; end
                                                                                14 : begin send_buffer = " "; rs =1; end
                                                                                15 : begin send_buffer = " "; rs =1; end
                                                                        endcase
                                                                        send =1; 
                                                                        cnt_string_b = cnt_string_b + 1;
                                                                        end
                                                                        else begin
                                                                                case(cnt_string_d)
                                                                                        0 : begin send_buffer = 8'hc0;  rs =0; end
                                                                                        1 : begin send_buffer = wrong[111 : 104]; rs =1; end
                                                                                        2 : begin send_buffer = wrong[103 : 96]; rs =1; end
                                                                                        3 : begin send_buffer = wrong[95 : 88]; rs =1; end
                                                                                        4 : begin send_buffer = wrong[87 : 80]; rs =1; end
                                                                                        5 : begin send_buffer = wrong[79 : 72]; rs =1; end
                                                                                        6 : begin send_buffer = wrong[71 : 64]; rs =1; end
                                                                                        7: begin send_buffer = wrong[63 : 56]; rs =1; end
                                                                                        8 : begin send_buffer = wrong[55 : 48]; rs =1; end
                                                                                        9 : begin send_buffer = wrong[47 : 40]; rs =1; end
                                                                                        10 :  begin send_buffer =  "2"- cnt_wrong_1;  rs =1; end
                                                                                        11 :  begin send_buffer = wrong[31 : 24]; rs =1; end
                                                                                        12 :  begin send_buffer = wrong[23 : 16]; rs =1; end
                                                                                        13 :  begin send_buffer = wrong[15 : 8]; rs =1; end
                                                                                        14 :  begin send_buffer = wrong[7: 0]; rs =1; end
                                                                                        15 : begin send_buffer = " "; rs =1; end
                                                                                    endcase
                                                                                    send =1; 
                                                                                    cnt_string_d = cnt_string_d + 1;            
                                                                        end                                             
                                                              end
                                                    end
                                        end
                                end
                            
                                

                                                            
                        endcase
                end
        end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
