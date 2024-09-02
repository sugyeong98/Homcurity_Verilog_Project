`timescale 1ns / 1ps
// clock divided 100 = 1usec
module clock_div_100(               
        input clk, reset_p,
        output clk_div_100,
        output clk_div_100_nedge);
        
        reg [6:0] cnt_sysclk;           
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= 99) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_div_100 = (cnt_sysclk < 50) ? 0 : 1;        
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_100), .n_edge(clk_div_100_nedge)); 
         
endmodule

module edge_detector_p(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
            end
            else begin      
                ff_old = ff_cur;
                ff_cur = cp;         
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule

// T-flipflop Edge Detector (negative)
module edge_detector_n(
        input clk, reset_p,
        input cp,           
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(negedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
            end
            else begin      
                ff_old = ff_cur;
                ff_cur = cp;       
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule

// button controller
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

//FND Ring counter(com)
module ring_counter_fnd(
        input clk, reset_p,
        output  reg [3:0] com);
        
        reg [20:0]  clk_div = 0;        
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

// decoder 7 segment
module decoder_7seg(
        input [3:0] hex_value,
        output reg [7:0] seg_7);
        
        always @(hex_value)begin
                case(hex_value)
                                                      //abcd_efgp  
                        4'b0000 : seg_7 = 8'b0000_0011;     // 0
                        4'b0001 : seg_7 = 8'b1001_1111;     // 1
                        4'b0010 : seg_7 = 8'b0010_0101;     // 2
                        4'b0011 : seg_7 = 8'b0000_1101;     // 3
                        4'b0100 : seg_7 = 8'b1001_1001;     // 4
                        4'b0101 : seg_7 = 8'b0100_1001;     // 5
                        4'b0110 : seg_7 = 8'b0100_0001;     // 6
                        4'b0111 : seg_7 = 8'b0001_1011;     // 7
                        4'b1000 : seg_7 = 8'b0000_0001;     // 8
                        4'b1001 : seg_7 = 8'b0000_1001;     // 9
                        4'b1010 : seg_7 = 8'b0001_0001;     // A(10)
                        4'b1011 : seg_7 = 8'b1100_0001;     // b(11)
                        4'b1100 : seg_7 = 8'b0110_0011;     // C(12)
                        4'b1101 : seg_7 = 8'b1000_0101;     // d(13)
                        4'b1110 : seg_7 = 8'b0110_0001;     // E(14)
                        4'b1111 : seg_7 = 8'b0111_0001;     // F(15)
                endcase
        end                

endmodule

// FND Controller
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

// PWM Controller
module pwm_Nstep_freq
 #(
        parameter   sys_clk_freq = 100_000_000,  // 100MHz
        parameter   pwm_freq = 10_000,
        parameter   duty_step = 100,
        parameter   temp = sys_clk_freq / duty_step / pwm_freq,
        parameter   temp_half = temp / 2)
(
        input clk, reset_p,
        input [31:0] duty,
        output pwm);
        
        integer cnt_sysclk;    
        integer cnt_duty;
        wire clk_freqXstep, clk_freqXstep_nedge;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_freqXstep = (cnt_sysclk < temp_half) ? 0 : 1; 
        
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_freqXstep), .n_edge(clk_freqXstep_nedge)); 
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_duty = 0;
                else if(clk_freqXstep_nedge)begin
                        if(cnt_duty >= (duty_step - 1)) cnt_duty = 0;
                        else cnt_duty = cnt_duty + 1;
                end
        end
        
        assign pwm = (cnt_duty < duty) ? 1 : 0;      // duty rate
        
endmodule

// binary to decimal controller
module bin_to_dec(
        input [11:0] bin,
        output reg [15:0] bcd
    );

    reg [3:0] i;

    always @(bin) begin
        bcd = 0;
        for (i=0;i<12;i=i+1)begin
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule

//dht11 controller
module dht11_cntrl(
        input clk, reset_p,
        inout dht11_data,
        output [15:0] led_debug,        // 현재 state 확인용
        output reg [7:0] humidity, temperature);
        
        parameter S_IDLE = 6'b00_0001; 
        parameter S_LOW_18MS = 6'b00_0010;
        parameter S_HIGH_20US = 6'b00_0100;
        parameter S_LOW_80US = 6'b00_1000;
        parameter S_HIGH_80US = 6'b01_0000;
        parameter S_READ_DATA = 6'b10_0000;
        
        parameter S_WAIT_PEDGE = 2'b01;
        parameter S_WAIT_NEDGE = 2'b10;
        
        reg [5:0] state, next_state;
        reg [1:0] read_state;
        
        assign led_debug[5:0] = state;
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
        
        // 마이크로세컨드 단위로 카운트 
        // enable 이 1이면 카운트 동작 , 1이 아니면 0으로 카운트 초기화 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = S_IDLE;
                else state = next_state;
        end
        
        // data을 in-out 선언 했으므로 reg 선언을 할 수 없음 
        reg dht11_buffer;
        assign dht11_data = dht11_buffer;
        
        // 엣지 디텍터 
        wire dht_nedge, dht_pedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .n_edge(dht_nedge), .p_edge(dht_pedge));
        
        reg [39:0] temp_data;
        reg [5:0] data_count;
        
        // 상태 천이도에 따른 case문  
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = S_IDLE;
                        read_state = S_WAIT_PEDGE;
                        temp_data = 0;
                        data_count = 0;
                end
                else begin
                        case(state)
                            S_IDLE : begin      // 기본상태
                                    if(count_usec < 22'd3_000_000)begin     // 3초동안 기다림
                                            count_usec_en = 1;    // usec 카운트 세기 시작   
                                            dht11_buffer = 'bz;     // 임피던스 출력하면 풀업에 의해 1이 된다(풀업저항이 달려잇음) 
                                    end
                                    else begin
                                            count_usec_en = 0;      // 카운트를 멈추고 초기화 시킴 
                                            next_state = S_LOW_18MS;    // 다음 state로 천이
                                    end         
                            end
                            S_LOW_18MS : begin      //  MCU에서 시작신호 발송상태 
                                    if(count_usec < 22'd20_000)begin        // 최소값이 18ms 이므로 여유있게 20ms 세팅 
                                            dht11_buffer = 0;       // 저장된 data 초기화 
                                            count_usec_en = 1;   // usec 카운트 시작 
                                    end       
                                    else begin      // 20ms 지나면 실행 
                                            count_usec_en = 0;      // 카운트 초기화
                                            next_state = S_HIGH_20US;   // 다음 상태로 천이 
                                            dht11_buffer = 'bz;     // data 임피던스 부여 -> 풀업에 의해 1
                                    end         
                            end
                            S_HIGH_20US : begin     // dht11으로부터의 응답비트 기다림(20us)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge) begin     // 응답이 들어오면(하강엣지 발생)
                                            count_usec_en = 0;
                                            next_state = S_LOW_80US;        // 다음 상태로 천이 
                                    end        
                            end
                            S_LOW_80US : begin      // dht11 응답비트 보냄(상승엣지 발생까지 )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_pedge)begin              // 데이터시트의 부정확성때문에 정확한 시간이 아닌 엣지를 기다림 
                                            next_state = S_HIGH_80US;
                                            count_usec_en = 0;
                                    end
                            end
                            S_HIGH_80US : begin     // dht11 응답비트 발생 확인(하강엣지 발생까지 )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge)begin      
                                            next_state = S_READ_DATA;  
                                             count_usec_en = 0;
                                    end
                            end
                            S_READ_DATA : begin     // dht11에서 데이터 신호 발생 시작(상승엣지 하강엣지 40번 반복)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                            data_count = 0;
                                            read_state = S_WAIT_PEDGE;
                                    end        
                                    else begin        
                                        case(read_state)
                                                S_WAIT_PEDGE : begin        // 상승엣지 기다림 상태 
                                                        if(dht_pedge) read_state = S_WAIT_NEDGE;
                                                end
                                                S_WAIT_NEDGE :  begin       // 하강엣지 기다림 상태
                                                        if(dht_nedge)begin
                                                                if(count_usec < 95)begin
                                                                        temp_data = {temp_data[38:0] , 1'b0};       // shift 레지스터(좌 시프트)
                                                                end
                                                                else begin
                                                                        temp_data = {temp_data[38:0] , 1'b1};
                                                                end
                                                                data_count = data_count + 1;
                                                                read_state = S_WAIT_PEDGE;
                                                                count_usec_en = 0; 
                                                        end
                                                        else begin
                                                                count_usec_en = 1;
                                                        end
                                                end
                                        endcase 
                                        if(data_count >= 40)begin   // 데이터 발송 비트가 40개가 되면 종료 -> 기본상태로 천이 
                                                data_count = 0;
                                                next_state = S_IDLE;
                                                count_usec_en = 0;
                                                read_state = S_WAIT_PEDGE;
                                                // check_sum 확인(오류 유무 확인)
                                                if(temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8] == temp_data[7:0])begin
                                                    humidity = temp_data[39:32];
                                                    temperature = temp_data[23:16];
                                                end    
                                        end 
                                    end          
                                end
                        endcase
                end        
        end
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////
// I2C protocol
module I2C_master(
        input clk, reset_p,
        input [6:0] addr,   // 주소
        input rd_wr,        // 읽고 쓰기
        input [7:0] data,   // data
        input comm_go,  // 스타트 신호
        output reg scl, sda,
        output reg [15:0] led);
        
        parameter IDLE                      = 7'b000_0001;
        parameter COMM_START    = 7'b000_0010;
        parameter SEND_ADDR       = 7'b000_0100;
        parameter RD_ACK               = 7'b000_1000;
        parameter SEND_DATA        = 7'b001_0000;
        parameter SCL_STOP           = 7'b010_0001;
        parameter COMM_STOP       = 7'b100_0001;
        
        wire [7:0] addr_rw;
        assign addr_rw = {addr, rd_wr};
        
        // 10usec LCD
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us         
        
        reg [2:0] count_usec5;
        reg scl_en;     // 1이 되어야 scl 동작
        always  @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    count_usec5 = 0;
                    scl = 1;        // IDLE 상태에서는 scl = 1
            end
            else if(scl_en)begin
                    if(clk_usec)begin
                            if(count_usec5 >= 4) begin
                            count_usec5 = 0;
                            scl = ~scl;
                            end
                            else count_usec5  = count_usec5 + 1;   
                    end 
            end
            else if(!scl_en)begin
                    scl = 1;
                    count_usec5 = 0;
            end
        end
        
        wire scl_nedge, scl_pedge, comm_go_pedge;
        edge_detector_n scl_edge(.clk(clk), .reset_p(reset_p), .cp(scl), .n_edge(scl_nedge), .p_edge(scl_pedge));
        edge_detector_n comm_edge(.clk(clk), .reset_p(reset_p), .cp(comm_go), .p_edge(comm_go_pedge));
        
        reg [6:0] state, next_state;
        always  @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        // FSM
        reg [2:0] cnt_bit;
        reg stop_flag;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        scl_en = 0;
                        sda = 1;        // IDLE 상테에서 sda, scl 1
                        cnt_bit = 7;        // MSB
                        stop_flag = 0;
                end
                else begin
                        case(state)
                            IDLE : begin
                                scl_en = 0;
                                sda = 1;
                                if(comm_go_pedge) next_state = COMM_START;
                            end
                            COMM_START : begin
                                sda = 0;
                                scl_en = 1;
                                next_state = SEND_ADDR;
                            end
                            SEND_ADDR : begin
                                if(scl_nedge) sda = addr_rw[cnt_bit];
                                if(scl_pedge)begin
                                    if(cnt_bit == 0)begin
                                        cnt_bit = 7;
                                        next_state = RD_ACK;
                                    end    
                                    else cnt_bit = cnt_bit - 1;
                                end    
                            end
                            RD_ACK : begin      // ACK 읽지 않음
                                if(scl_nedge) sda = 'bz;        // 임피던스 출력으로 출력을 끊어줌
                                else if(scl_pedge)begin         // one-clock 보냄
                                    if(stop_flag)begin
                                        stop_flag = 0;
                                        next_state = SCL_STOP;
                                    end
                                    else begin
                                        stop_flag = 1;
                                        next_state = SEND_DATA;
                                    end
                                end    
                            end
                            SEND_DATA : begin
                                if(scl_nedge) sda = data[cnt_bit];
                                if(scl_pedge)begin
                                    if(cnt_bit == 0)begin
                                        cnt_bit = 7;
                                        next_state = RD_ACK;
                                    end    
                                    else cnt_bit = cnt_bit - 1;
                                end    
                            end
                            SCL_STOP : begin
                                if(scl_nedge) sda = 0;
                                else if(scl_pedge) next_state = COMM_STOP;
                            end
                            COMM_STOP : begin
                                if(count_usec5 >= 3)begin
                                        scl_en = 0;
                                        sda = 1;
                                        next_state = IDLE;
                                end
                            end
                        endcase     
                end
        end
endmodule

module i2c_lcd_send_byte(
        input clk, reset_p,
        input [6:0] addr,
        input [7:0] send_buffer,
        input rs, send,
        output scl, sda,
        output reg busy,
        output [15:0] led);
    
        parameter   IDLE                                          = 6'b00_0001;      
        parameter   SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;      // 4bit = nibble
        parameter   SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
        parameter   SEND_LOW_NIBBLE_DISABLE = 6'b00_1000;
        parameter   SEND_LOW_NIBBLE_ENABLE  = 6'b01_0000;
        parameter   SEND_DISABLE                        = 6'b10_0000;
        
        reg [7:0] data;
        reg comm_go;
         I2C_master master( .clk(clk), .reset_p(reset_p),
                .addr(addr),
                .rd_wr(0),         
                .data(data),
                .comm_go(comm_go), 
                .scl(scl), .sda(sda),
                .led(led));
       
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us         
        
        wire send_pedge;
        edge_detector_n send_edge(.clk(clk), .reset_p(reset_p), .cp(send), .n_edge(send_nedge), .p_edge(send_pedge));
        
        // count
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        // FSM
        reg [5:0] state, next_state;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        busy = 0;
                        comm_go = 0;
                        count_usec_en = 0;
                        data = 0;
                end
                else begin
                        case(state)
                                IDLE : begin
                                       if(send_pedge)begin
                                            next_state = SEND_HIGH_NIBBLE_DISABLE;
                                            busy = 1;
                                       end
                                end
                                SEND_HIGH_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec 만큼 기다림(데이터 전송시간)
                                            data = {send_buffer[7:4], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_HIGH_NIBBLE_ENABLE;
                                        end
                                end
                                SEND_HIGH_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec 만큼 기다림(데이터 전송시간)
                                            data = {send_buffer[7:4], 3'b110, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_LOW_NIBBLE_DISABLE;
                                        end
                                end
                                SEND_LOW_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec 만큼 기다림(데이터 전송시간)
                                            data = {send_buffer[3:0], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_LOW_NIBBLE_ENABLE;
                                        end
                                end
                                SEND_LOW_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec 만큼 기다림(데이터 전송시간)
                                            data = {send_buffer[3:0], 3'b110, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_DISABLE;
                                        end
                                end
                                SEND_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec 만큼 기다림(데이터 전송시간)
                                            data = {send_buffer[3:0], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = IDLE;
                                            busy = 0;
                                        end
                                end
                        endcase
                end
        end
endmodule
///////////////////////////////////////////////////////////////////////////////////////////////
// external lcd
module i2c_txtlcd_external(
        input clk, reset_p,
        input flame_flag,
        input security_on,
        input pir_flag,
        output scl, sda);
        
        parameter   IDLE = 4'b0001;
        parameter   INIT = 4'b0010;
        parameter   SEND_MENTION_FIRE = 4'b0100;
        parameter   SEND_MENTION_SECURITY  = 4'b1000;
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us        
        
        wire flame_nedge, flame_pedge, pir_nedge, pir_pedge;
        edge_detector_n flame_edge(.clk(clk), .reset_p(reset_p), .cp(flame_flag), .n_edge(flame_nedge), .p_edge(flame_pedge));
        edge_detector_n security_edge(.clk(clk), .reset_p(reset_p), .cp(pir_flag), .n_edge(pir_nedge), .p_edge(pir_pedge));
        
        reg rs, send;
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        reg [7:0] send_buffer;
        wire busy;
        i2c_lcd_send_byte txtlcd( .clk(clk), .reset_p(reset_p),
                .addr(7'h27),
                .send_buffer(send_buffer),
                .rs(rs), .send(send),
                .scl(scl), .sda(sda),
                .busy(busy),
                .led(led));
        
        reg [3:0] state, next_state;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        reg init_flag;
        reg [3:0] count_data;
        reg [8*5-1:0] mention;
        reg [8*16-1:0] mention2;
        reg [4:0] count_mention, count_mention2;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        init_flag = 0;
                        count_usec_en = 0;
                        send = 0;
                        rs = 0;
                        mention = "FIRE!";
                        mention2 = "DETECTED WARNING";
                        count_mention = 0;
                        count_mention2 = 0;
                end
                else begin
                        case(state)
                                IDLE : begin
                                        if(init_flag)begin
                                                    if(flame_pedge) next_state = SEND_MENTION_FIRE;  // 비밀번호 성공 플래그 선언 자리
                                                    if(pir_pedge && security_on) next_state = SEND_MENTION_SECURITY;  // 비밀번호 성공 플래그 선언 자리
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
                                                        3 : send_buffer = 8'b0000_1100;        // Display On = 1, Cursor On = 1, Blinking Cursor On = 0
                                                        4 : send_buffer = 8'b0000_0001;        // Clear Display = 1
                                                        5 : send_buffer = 8'b0000_0110;        // Cursor Direction = 1 , Shift = 0
                                                        5 : send_buffer = 8'b0000_0110;        // Cursor Direction = 1 , Shift = 0
                                                endcase
                                                rs = 0;
                                                send = 1;
                                                count_data = count_data + 1;
                                        end
                                end
                                SEND_MENTION_SECURITY : begin
                                        if(busy)begin         
                                                send = 0;
                                                if(count_mention2 >= 16)begin
                                                        next_state = IDLE;
                                                        count_mention2 = 0;
                                                end
                                        end                           
                                        else if(!send)begin
                                                case(count_mention2)
                                                        0 : send_buffer = mention2[127:120];
                                                        1 : send_buffer = mention2[119:112];
                                                        2 : send_buffer = mention2[111:104];      
                                                        3 : send_buffer = mention2[103:96];      
                                                        4 : send_buffer = mention2[95:88];    
                                                        5 : send_buffer = mention2[87:80];    
                                                        6 : send_buffer = mention2[79:72];    
                                                        7 : send_buffer = mention2[71:64];    
                                                        8 : send_buffer = mention2[63:56];    
                                                        9 : send_buffer = mention2[55:48];    
                                                        10 : send_buffer = mention2[47:40];    
                                                        11 : send_buffer = mention2[39:32];    
                                                        12 : send_buffer = mention2[31:24];    
                                                        13 : send_buffer = mention2[23:16];    
                                                        14 : send_buffer = mention2[15:8];    
                                                        15 : send_buffer = mention2[7:0];    
                                                endcase
                                                rs = 1;
                                                send = 1;
                                                count_mention2 = count_mention2 + 1;
                                        end
                                end
                                SEND_MENTION_FIRE : begin
                                        if(busy)begin         
                                                send = 0;
                                                if(count_mention >= 5)begin
                                                        next_state = IDLE;
                                                        count_mention = 0;
                                                end
                                        end                           
                                        else if(!send)begin
                                                case(count_mention)
                                                        0 : send_buffer = mention[39:32];    
                                                        1 : send_buffer = mention[31:24];    
                                                        2 : send_buffer = mention[23:16];    
                                                        3 : send_buffer = mention[15:8];    
                                                        4 : send_buffer = mention[7:0];    
                                                endcase
                                                rs = 1;
                                                send = 1;
                                                count_mention = count_mention + 1;
                                        end
                                end

                        endcase
                end         
        end
endmodule

////////////////////////////////////////////////////////////////////////////////
// flame
module flame_sensor(
    input clk, reset_p,
    input [11:0] adc_value_flame,
    output reg flame_flag,
    output [15:0] flame_value,
    output servo_pwm,
    output reg buzz_flame);
    
    bin_to_dec btd( .bin(adc_value_flame), .bcd(flame_value));
    
    always  @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    buzz_flame = 0;
                    flame_flag = 0;
            end
            else if(flame_value > 7'd60)begin
                    buzz_flame = 1;
                    flame_flag = 1;
            end
            else begin
                    buzz_flame = 0;
            end                
    end
    
    servo_motor_flame( .clk(clk), .reset_p(reset_p), .flame_flag(flame_flag), .servo_pwm(servo_pwm));
    
endmodule
////////////////////////////////////////////////////////////////////////////
// fire window
module servo_motor_flame(
        input clk, reset_p,
        input flame_flag,
        output servo_pwm);
        
        wire flame_nedge, flame_pedge;
        edge_detector_n flame_edge(.clk(clk), .reset_p(reset_p), .cp(flame_flag), .n_edge(flame_nedge), .p_edge(flame_pedge));
        
        reg [3:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) begin duty = 3; end  // 초기값 설정 
                else if(!flame_flag) begin duty = 3; end   // 0도
                else if(flame_pedge) begin duty = 8;  end  // 90도 
        end 
        
        pwm_Nstep_freq #(.duty_step(100), .pwm_freq(50))
                                      pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(servo_pwm));

endmodule
//////////////////////////////////////////
// dht fan
module  dht11_fan_smart(
        input clk,reset_p,
        input smart_switch,
        inout dht11_data,
        output motor_pwm,
        output [15:0] value
);
                
        wire [7:0] humidity, temperature;       // 온습도 데이터값 출력 
        dht11_cntrl( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));
        
        wire [15:0] humidity_bcd, temperature_bcd;  // 2진화 10진수 변환 
        bin_to_dec  bcd_humidity( .bin({4'b0, humidity}), .bcd(humidity_bcd));  // 총 12비트 중 8비트만 사용
        bin_to_dec  bcd_temperature( .bin({4'b0, temperature}), .bcd(temperature_bcd));
        
        assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};   
        
        reg [5:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        duty = 0;
                end
                else if(!smart_switch) duty = 0;            
                else begin
                        if(temperature >= 8'd26 && temperature < 8'd28) duty = 1;
                        else if(temperature >= 8'd28 && temperature < 8'd30) duty = 2;
                        else if(temperature >= 8'd30) duty = 3;
                        else duty = 0;
                end
        end
        
         pwm_Nstep_freq #( .duty_step(4), .pwm_freq(100))
         pwm_motor(
            .clk(clk),        
            .reset_p(reset_p), 
            .duty(duty),      
            .pwm(motor_pwm)     
        ); 
        
endmodule    
////////////////////////////////////////////////////////////////////////////////////
// standard(non-smart) fan
module dc_motor_fan_standard(
        input clk, reset_p,
        input btn_fan,
        output [15:0] led,
        output motor_pwm);
        
        wire btn_fan_step;  
        button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn_fan), .btn_pedge(btn_fan_step));
       
        reg [2:0] led_count;
        reg [5:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        duty = 0;
                end
                else if(btn_fan_step) begin
                        duty = duty + 1;
                        if(duty >= 4) duty = 0;
                end
        end
       
        always @(posedge clk or posedge reset_p)begin
                    if(reset_p) led_count = 3'b000;
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
       
 endmodule
 ////////////////////////////////////////////////////////
 // pir sensor
 module pir_sensor(
    input clk, reset_p,
    input  pir_input,
    output reg pir_sensor);

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            pir_sensor = 0;    // 리셋 시 출력 초기화
        end else begin
            pir_sensor = pir_input;  // PIR 센서의 상태를 pir_sensor로 출력
        end
    end
endmodule
/////////////////////////////////////////////
//현관등
module door_light(
    input clk, reset_p,
    input pir_input,
    output reg door_led);  // auto 모드 LED 밝기 제어);

    wire pir_sensor;
    reg [31:0] pir_timeout_counter; // 타이머 카운터
    reg pir_detected; // PIR 센서 감지 상태 플래그
    reg auto_mode; // auto_switch 활성화 상태를 유지

    // PIR 센서 모듈 인스턴스화
    pir_sensor pir_inst (
        .clk(clk),
        .reset_p(reset_p),
        .pir_input(pir_input),
        .pir_sensor(pir_sensor));

    // LED 제어
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            door_led = 0;
            pir_timeout_counter = 0;
            pir_detected = 0;
            auto_mode = 0;
        end 
        else begin
                if (pir_sensor) begin
                    // PIR 센서가 감지되면 LED 밝기 조절
                    door_led = 1;
                    pir_detected = 1; // PIR 센서 감지됨
                    pir_timeout_counter = 0; // 타이머 리셋
                end 
                else begin
                    if (pir_detected) begin
                        // PIR 센서가 감지되지 않으면서 이전에 감지된 상태였던 경우
                        if (pir_timeout_counter >= 32'd833_333_333) begin // 10초동안 켜짐
                            // 10초 지났다면 LED 끄기
                            door_led = 0;
                            auto_mode = 0;
                            pir_detected = 0; // 감지 상태 플래그 리셋
                        end 
                        else begin
                            pir_timeout_counter = pir_timeout_counter + 1; // 타이머 증가
                            door_led = 1; // PIR 센서가 감지되지 않으면서 이전에 감지된 상태일 때 LED 켜짐
                        end
                    end 
                    else begin
                        // PIR 센서가 감지되지 않았고 이전에 감지 상태도 아니었던 경우
                        door_led = 0;
                    end
                end
            end 
        end
endmodule
////////////////////////////////////////////////
//거실등
module livingroom_light(
    input clk, reset_p,
    input smart_switch, led_switch, // 스위치 변수 
    input [11:0] adc_value_cds,
    output reg livingroom_led,  // auto 모드 LED 밝기 제어
    output reg standard_led,    // 수동 모드  LED 제어
    output [15:0] cds_value
    );
    
    bin_to_dec  bcd( .bin({4'b0, adc_value_cds[11:4]}), .bcd(cds_value));  // 총 12비트 중 8비트만 사용
    
    wire led_pwm;
    pwm_Nstep_freq #(.duty_step(200),  .pwm_freq(10000))
    pwm_backlight( .clk(clk), .reset_p(reset_p), .duty(adc_value_cds[11:4]), .pwm(led_pwm));
    
    // LED 제어
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            livingroom_led = 0;
            standard_led = 0;
        end 
        else begin
            // auto_switch가 켜져 있을 때
            if (smart_switch) livingroom_led = ~led_pwm; // PIR 센서가 감지되지 않으면서 이전에 감지된 상태일 때 LED 켜짐
            else if(!smart_switch)begin 
                livingroom_led = 0;
                if(led_switch) standard_led = 1;
                else if(!led_switch) standard_led = 0;
            end
        end
    end
endmodule
////////////////////////////////////////////////////////////////
// 방범모드(인체감지센서) - 부저 +  LCD
module security_pir(
    input clk, reset_p,
    input pir_input,
    input security_on,
    output pir_flag,
    output reg buzz_pir
);
    pir_sensor(.clk(clk), .reset_p(reset_p), .pir_input(pir_input), .pir_sensor(pir_flag));   // pir_sensor : 감지 시 1 
    
    // 부저 알림 
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            buzz_pir = 0;
        end
        else begin
            if(pir_flag && security_on)begin
                buzz_pir = 1;
            end
            else buzz_pir = 0;
        end
    end    
    
endmodule

///////////////////////////////////////////////////////
module servo_motor_door(
        input clk, reset_p,
        input open_flag, flame_flag,
        output servo_door);
        
        wire open_nedge, open_pedge, flame_nedge, flame_pedge;
        edge_detector_n open_edge(.clk(clk), .reset_p(reset_p), .cp(open_flag), .n_edge(open_nedge), .p_edge(open_pedge));
        edge_detector_n flame_edge(.clk(clk), .reset_p(reset_p), .cp(flame_flag), .n_edge(flame_nedge), .p_edge(flame_pedge));
        reg [3:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) begin duty = 3; end  // 초기값 설정 
                else if(open_nedge) duty =3;
                else if(flame_pedge) duty = 8; 
                else if(open_pedge)  duty = 8; // 90도
        end 
        
        pwm_Nstep_freq #(.duty_step(100), .pwm_freq(50))
                                      pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(servo_door));

endmodule

//////////////////////////////////////////////////////////////////////////////////
module doorlock_keypad(
            input clk, reset_p,
            input [3:0] row,
            input [3:0] btn,
            output sda, scl,
            output [15:0] led,
            output [3:0] col,
            output [3:0] com,
            output [7:0] seg_7,
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
        i2c_lcd_send_byte( .clk(clk), .reset_p(reset_p), .addr(7'h27),.send_buffer(send_buffer), .rs(rs), .send(send) ,.scl(scl), .sda(sda),.busy(busy), .led(led)); 
        
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
                                                        open_flag =0;       
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
                                                                        12 :  begin send_buffer = correct[7: 0]; rs =1;end
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
module keypad_cntr_FSM(
         input clk, reset_p,
         input [3:0] row,   // 행 
         output reg [3:0] col,  //column 열 
         output reg [3:0] key_value,
         output reg key_valid);
         
         parameter SCAN0                        = 5'b00001;
         parameter SCAN1                         = 5'b00010;
         parameter SCAN2                        = 5'b00100;
         parameter SCAN3                        = 5'b01000;
         parameter KEY_PROCESS       = 5'b10000;
         
         
         reg [19:0] clk_div;
         always @(posedge clk) clk_div = clk_div+1;
        
        wire clk_8msec_n, clk_8msec_p;
        edge_detector_p        ed       (.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n),  .p_edge(clk_8msec_p));
        
        
       reg [4:0] state, next_state;
       
       always @(posedge clk or posedge reset_p)begin
                if(reset_p) state = SCAN0;
                else if(clk_8msec_n)state = next_state;
       end
       
       
       always @* begin   //와일드카드 모든 경우에 동작 (조합회로인데 앞에else if(clk_8msec)state = next_state로 인해 순서회로처럼 동작 )
                    case(state)
                            SCAN0 : begin
                                    if(row ==0) next_state = SCAN1;      // 버튼이 눌리면 
                                    else next_state = KEY_PROCESS;                  // 버튼이 안눌리면
                            end 
                            
                            SCAN1 : begin
                                    if(row ==0) next_state = SCAN2;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            SCAN2 : begin
                                    if(row ==0) next_state = SCAN3;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            SCAN3 : begin
                                    if(row ==0) next_state = SCAN0;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            KEY_PROCESS : begin
                                    if(row ==0) next_state = SCAN0;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            default : next_state = SCAN0;
                    endcase
        end
        
  always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                        key_value = 0;
                        key_valid = 0;
                        col =0;
                end
                else if(clk_8msec_p)begin
                        case(state)
                                SCAN0 : begin col = 4'b0001; key_valid = 0; end
                                SCAN1 : begin col = 4'b0010; key_valid = 0; end
                                SCAN2 : begin col = 4'b0100; key_valid = 0; end
                                SCAN3 : begin col = 4'b1000; key_valid = 0; end
                                KEY_PROCESS : begin
                                            key_valid = 1;
                                                 case({col, row})
                                                 8'b0001_0001 : key_value = 4'h7;
                                                 8'b0001_0010 : key_value = 4'h4;
                                                 8'b0001_0100 : key_value = 4'h1;
                                                 8'b0001_1000 : key_value = 4'hc;
                                                 8'b0010_0001 : key_value = 4'h8;
                                                 8'b0010_0010 : key_value = 4'h5;
                                                 8'b0010_0100 : key_value = 4'h2;
                                                 8'b0010_1000 : key_value = 4'h0;
                                                 8'b0100_0001 : key_value = 4'h9;
                                                 8'b0100_0010 : key_value = 4'h6;
                                                 8'b0100_0100 : key_value = 4'h3;
                                                 8'b0100_1000 : key_value = 4'hf;
                                                 8'b1000_0001 : key_value = 4'ha;
                                                 8'b1000_0010 : key_value = 4'hb;
                                                 8'b1000_0100 : key_value = 4'he;
                                                 8'b1000_1000 : key_value = 4'hd;      
                                                 endcase  
                                end
                        endcase
               end
end

endmodule
