`timescale 1ns / 1ps

module AHB2BUTTON(
input wire HCLK,
input wire HRESETn,
input wire button_in,

output wire button_out,     // �ⲿ����������ֵ
output reg button_tick
);
    
localparam st_idle   = 2'b00;
localparam st_wait1  = 2'b01;
localparam st_stable = 2'b10;
localparam st_wait0  = 2'b11;
    
    reg [1:0] current_state = st_idle;  // ��ǰ״̬
    reg [1:0] next_state = st_idle;     // ��һ��״̬
    
    reg [21:0] db_clk = {21{1'b1}};         // ������������reg�����ڼ��״̬�Ƿ�ά��һ��ʱ��
    reg [21:0] db_clk_next = {21{1'b1}};
    
    always @(posedge HCLK or negedge HRESETn) begin // ����ϵͳ�Ľ׶�
        if(!HRESETn) begin
            current_state <= st_idle;
            db_clk <= 0;
        end else begin                  // ��������£�����һ��״̬������ǰ״̬������ʱ��Ҳ�ı�
            current_state <= next_state;
            db_clk <= db_clk_next;
        end
    end
    
    always @(*) begin
        next_state = current_state;     // Ĭ�ϲ��ı�ϵͳ״̬����Ҫ����ǰ״̬���ⲿ�����������ȷ����θı�״̬
        db_clk_next = db_clk;
        button_tick = 0;        // ����֪���Ǹ����õ�
        
        case (current_state)        // ���ݵ�ǰ״̬�����ָı�ϵͳ״̬
            st_idle : begin     // ����
                if(button_in) begin   // ����ڿ���״̬���а�������
                    db_clk_next = {21{1'b1}};       // ���ڼ����ﵽ�ȶ���Ҫ��ʱ��
                    next_state = st_wait1;      // �����鵽�������£���ı�״̬������ȴ����������ź��ȶ���״̬
                end
            end
            st_wait1 : begin    // �а������£��ȴ��ź��ȶ�
                if(button_in) begin
                    db_clk_next = db_clk - 1;
                    if(db_clk_next == 0) begin      // ȷ���ﵽ�ȶ�״̬
                        next_state = st_stable;
                        button_tick = 1'b1;     // ?
                    end
                end
            end
            st_stable : begin   // �ź��Ѿ��ȶ�
                if(~button_in) begin       // ��ǰ���ȶ���״̬����⵽�����ͷŵĲ���
                    next_state = st_wait0;
                    db_clk_next = {21{1'b1}}; 
                end
            end
            st_wait0 : begin    // ȷ�������Ƿ�����ͷ�
                if(~button_in) begin
                    db_clk_next = db_clk - 1;
                    if(db_clk_next == 0) begin      // ȷ����������ͷ�
                        next_state = st_idle;
                    end
                end else begin  // ֮ǰ��⵽�İ����ͷ���һ��ë�̣�Ӧ�ú���
                    next_state = st_stable;
                end
            end
        endcase
    end
    
    assign button_out = (current_state == st_stable || current_state == st_wait0) ? 1'b1 : 1'b0;
    
endmodule
