`timescale 1ns / 1ps

module AHB2UART(
input wire HCLK,
input wire HRESETn,

input wire HSEL,

/* AHB���߽ӿ� */
input wire [31:0] HADDR,
input wire [1:0] HTRANS,
input wire [31:0] HWDATA,
input wire HWRITE,
input wire HREADY,
output wire HREADYOUT,
output wire [31:0] HRDATA,

/* uart�Ĵ����ź��� */
input wire RsRx,
output wire RsTx,

/* uart�������ж� */
output wire uart_irq
);

    wire [7:0] uart_wdata;      // ��ȡͨ��AHB���ߴ����Ҫͨ�����ڽ��д��������
    wire [7:0] uart_rdata;      // ͨ��uart���յ������ݣ�׼��ͨ��AHB���ߴ���cpu
                                // �������ߺ�AHB�ӿ���
    
    wire uart_wr;       // �������߱�ǵ��ǵ�ǰuart�Ƿ��ж�д����������ͬʱ��д��
    wire uart_rd;
    
    wire [7:0] tx_data;     // ��fifo�л�ȡһ���ֽں�ͨ��tx�����ȥ
    wire [7:0] rx_data;     // ���ⲿrx��ȡһ���ֽں󣬴���fifo
    wire [7:0] status;      // uart��״̬��empty��full����������cpu��
    
    wire tx_full;       // ��4���ź����ڱ�ʾ����fifo��empty/full���
    wire tx_empty;
    wire rx_full;
    wire rx_empty;
    
    wire tx_done;   
    wire rx_done;
    
    wire b_tick;        // �����ʷ������������ź�
    
    reg [1:0] last_HTRANS;
    reg [31:0] last_HADDR;
    reg last_HWRITE;
    reg last_HSEL;
    
    always @(posedge HCLK) begin
        if(HREADY) begin
            last_HTRANS <= HTRANS;
            last_HWRITE <= HWRITE;
            last_HSEL <= HSEL;
            last_HADDR <= HADDR;
        end
    end
    
    assign HREADYOUT = ~tx_full;        // ���źű�ʾ�������豸˵����ǰuart�豸�Ƿ���ã���tx_full��ʱ�򣬱�ʾtx fifo���ˣ���ʱcpu������uart��������
    
    assign uart_wr = last_HTRANS[1] & last_HWRITE & last_HSEL & (last_HADDR[7:0] == 8'h00);
    
    assign uart_wdata = HWDATA[7:0];
    
    assign uart_rd = last_HTRANS[1] & ~last_HWRITE & last_HSEL & (last_HADDR[7:0] == 8'h00);
    
    assign HRDATA = (last_HADDR[7:0] == 8'h00) ? {24'h0000_00, uart_rdata}:{24'h0000_00, status};
    assign status = {6'b000000, tx_full, rx_empty};
    
    assign uart_irq = ~rx_empty;    // ���ڱ�ʾreceiver fifo�Ƿ��ǿյģ�����������ʾuart�Ѿ����յ����ݣ�cpu��������ȡ�����Ǿ���cpu�����ж�
    
    baud_generator u_baud_generator(        // �����ʷ�����
    .clk (HCLK),
    .reset_n (HRESETn),
    .baud_tick (b_tick)
    );
    
    fifo #(.DWIDTH(8), .AWIDTH(4)) u_fifo_tx(   // uart��transfer FIFO
    .clk (HCLK),
    .reset_n (HRESETn),
    
    .rd (tx_done),
    .wr (uart_wr),
    .w_data (uart_wdata[7:0]),
    .r_data (tx_data[7:0]),
    
    .empty (tx_empty),
    .full (tx_full)
    );
    
    fifo #(.DWIDTH(8), .AWIDTH(4)) u_fifo_rx(   // uart��receiver FIFO
        .clk (HCLK),
        .reset_n (HRESETn),
        
        .rd (uart_rd),
        .wr (rx_done),
        .w_data (rx_data[7:0]),
        .r_data (uart_rdata[7:0]),
        
        .empty (rx_empty),
        .full (rx_full)
        );
        
    uart_receiver u_uart_receiver(  // uart������
        .clk (HCLK),
        .reset_n (HRESETn),
        
        .baud_tick (b_tick),
        .rx (RsRx),
        
        .rx_done (rx_done),
        .dout (rx_data[7:0])
        ); 
    
    uart_transfer u_uart_transfer(  //  uart������
        .clk (HCLK),
        .reset_n (HRESETn),
        
        .tx_start (!tx_empty),
        .b_tick (b_tick),
        .d_in (tx_data[7:0]),
        
        .tx_done (tx_done),
        .tx (RsTx)
        );
    
endmodule
