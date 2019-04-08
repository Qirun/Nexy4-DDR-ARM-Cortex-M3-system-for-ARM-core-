`timescale 1ns / 1ps

module fifo #(parameter DWIDTH = 8, AWIDTH = 1)(
input wire clk,
input wire reset_n,

input wire rd,
input wire wr,
input wire [7:0] w_data,

output wire empty,
output wire full,
output wire [7:0] r_data
);

    reg [DWIDTH - 1:0] array_reg [2**AWIDTH - 1:0];     // ����2^AWIDTH���Ĵ�����ÿ���Ĵ���ΪDWIDTHλ�����ڱ���FIFO�е�ÿһ���ֽ�
    reg [AWIDTH - 1:0] w_ptr_reg;       // ��ǰ�������FIFO�е���һ���ֽ�
    reg [AWIDTH - 1:0] w_ptr_next;      // ��һ���������FIFO�е���һ���ֽ�
    reg [AWIDTH - 1:0] w_ptr_succ;      // ������ʱ����ָ����һ��Ҫָ���λ�� 
    reg [AWIDTH - 1:0] r_ptr_reg;
    reg [AWIDTH - 1:0] r_ptr_next;
    reg [AWIDTH - 1:0] r_ptr_succ;    
    
    reg full_reg;       // �������FIFO�Ƿ�������Ϣ
    reg empty_reg;      // �������FIFO�Ƿ�յ���Ϣ
    reg full_next;
    reg empty_next;
    
    wire w_en;
    
    assign w_en = wr & ~full_reg;   // д�źţ���FIFOû��������FIFO����д������������
    assign full = full_reg;
    assign empty = empty_reg;
    
    always @(posedge clk) begin
        if(w_en) begin              // �����ǰ����ִ��д���������д����д��FIFO�ļĴ�����
            array_reg[w_ptr_reg] <= w_data;  // w_ptr_regָ����ǵ�ǰFIFO�пյ�
        end
    end
    
    assign r_data = array_reg[r_ptr_reg];
    
    always @(posedge clk or negedge reset_n) begin      // ״̬/�׶�ת��
        if(!reset_n) begin      // �ø����ʾ״̬�ļĴ�������
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;            
        end
    end
    
    always @(*) begin
        w_ptr_succ = w_ptr_reg + 1;     // �ô�ÿһ���׶Σ�w_ptr_reg��һ���ı䡣����ֵ�ӵ�ͷ֮����Զ���Ϊ0
        r_ptr_succ = r_ptr_reg + 1;
    
        w_ptr_next = w_ptr_reg;     // Ĭ������£����ı�״̬�������ж�д����������
        r_ptr_next = r_ptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;
        
        case ({w_en, rd})
            2'b01 :  begin      // ��д���ж�����
                if(~empty_reg) begin
                    r_ptr_next = r_ptr_succ;
                    full_next = 1'b0;
                    if(r_ptr_succ == w_ptr_reg) begin       // ��������ָ��ָ��д������ʱ�򣬱�ʾд��û���ü�д������һ�εĶ����������ܽ���
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10 :  begin      // д����������
                if(~full_reg) begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if(w_ptr_succ == r_ptr_reg) begin       // д������ָ��ָ���������ʱ�򣬱�ʾ�´��²������֮ǰ��û���ߵ����ݸ��ǵ��������´β���д
                        full_next = 1'b1;
                    end
                end
            end
            2'b11 :  begin      // ��д���ֶ�
                w_ptr_next = w_ptr_succ;
                r_ptr_next = r_ptr_succ;
            end                        
        endcase
    end

endmodule
