`timescale 1ns / 1ps

module uart_receiver(
input wire clk,
input wire reset_n,

input baud_tick,
input wire rx,

output reg rx_done,
output wire [7:0] dout
);
localparam [1:0] idle_st  = 2'b00;    
localparam [1:0] start_st = 2'b01;
localparam [1:0] data_st  = 2'b11;
localparam [1:0] stop_st  = 2'b10;      
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [3:0] b_reg;        // ������/������������
    reg [3:0] b_next;
    reg [2:0] count_reg;    // ����λ������
    reg [2:0] count_next;
    reg [7:0] data_reg;     // ���ݼĴ���
    reg [7:0] data_next;
    
    always @(posedge clk or negedge reset_n) begin          // ״̬ת��
        if(!reset_n) begin
            current_state <= idle_st;
            b_reg <= 0;
            count_reg <= 0;
            data_reg <= 0;
        end else begin
            current_state <= next_state;
            b_reg <= b_next;
            count_reg <= count_next;
            data_reg <= data_next;
        end
    end   
    
    always @(*) begin
        next_state = current_state;     // Ĭ������²��ı�״̬
        b_next = b_reg;
        count_next = count_reg;
        data_next = data_reg;
        rx_done = 1'b0;         // Ĭ������£�����û�����
        
        case (current_state)
            idle_st : begin     // ����
                if(~rx) begin          // �͵�ƽ��ʾ��ʼλ
                    next_state = start_st;
                    b_next = 0;
                end
            end
            start_st : begin    // ��ʼλ
                if(baud_tick) begin
                    if(b_reg == 7) begin
                        next_state = data_st;
                        b_next = 0;
                        count_next = 0;
                    end else begin
                        b_next = b_reg + 1'b1;
                    end
                end
            end
            data_st : begin     // ����λ
                if(baud_tick) begin
                    if(b_reg == 15) begin
                        b_next = 0;
                        data_next = {rx, data_reg[7:1]};
                        if(count_next == 7) begin
                            next_state = stop_st;
                        end else begin
                            count_next = count_reg + 1'b1;
                        end
                    end else begin
                        b_next = b_reg + 1;
                    end
                end
            end
            stop_st : begin     // ����λ
                if(baud_tick) begin
                    if(b_reg == 15) begin
                        next_state = idle_st;
                        rx_done = 1'b1;
                    end else begin
                        b_next = b_reg + 1;
                    end
                end
            end
        endcase
    end
    
    assign dout = data_reg;
    
endmodule
